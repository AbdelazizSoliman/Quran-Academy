require "rails_helper"

RSpec.describe "Public homepage catalog sections" do
  let(:academy_setting) { create(:academy_setting) }

  before { create(:public_website_setting, academy_setting:) }

  it "hides both featured sections cleanly when nothing is published" do
    create(:program, :active, name_en: "Unpublished Program")
    create(:fee_plan, name_en: "Unpublished Plan")

    get localized_public_home_path(locale: :en)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(I18n.t("public.home.programs.title", locale: :en))
    expect(response.body).not_to include(I18n.t("public.home.fees.title", locale: :en))
    expect(response.body).not_to include("Unpublished Program", "Unpublished Plan")
  end

  it "shows only featured published programs in public display order" do
    create(:program, :published, :featured, name_en: "Second Featured", public_display_order: 5)
    create(:program, :published, :featured, name_en: "First Featured", public_display_order: 1)
    create(:program, :published, name_en: "Published Not Featured")

    get localized_public_home_path(locale: :en)

    expect(response.body).to include(I18n.t("public.home.programs.title", locale: :en))
    expect(response.body.index("First Featured")).to be < response.body.index("Second Featured")
    expect(response.body).not_to include("Published Not Featured")
    expect(response.body).to include(public_programs_path(locale: :en))
  end

  it "shows published fee plans in public display order and bounds the count" do
    create(:fee_plan, :published, name_en: "Third Plan", public_display_order: 3)
    create(:fee_plan, :published, name_en: "First Plan", public_display_order: 1)
    create(:fee_plan, :published, name_en: "Second Plan", public_display_order: 2)
    create(:fee_plan, :published, name_en: "Fourth Plan", public_display_order: 4)

    get localized_public_home_path(locale: :en)

    expect(response.body).to include(I18n.t("public.home.fees.title", locale: :en))
    expect(response.body).to include("First Plan", "Second Plan", "Third Plan")
    expect(response.body).not_to include("Fourth Plan")
    expect(response.body).to include(public_fees_path(locale: :en))
  end

  it "renders the featured sections in Arabic without leaking English content" do
    create(:program, :published, :featured, name_ar: "برنامج مميز", name_en: "Featured English Program")
    create(:fee_plan, :published, name_ar: "خطة مميزة", name_en: "Featured English Plan")

    get localized_public_home_path(locale: :ar)

    expect(response.body).to include("برنامج مميز", "خطة مميزة")
    expect(response.body).not_to include("Featured English Program", "Featured English Plan")
  end

  it "keeps the homepage unavailable behaviour when the website is disabled" do
    academy_setting.public_website_setting.update!(enabled: false)
    create(:program, :published, :featured, name_en: "Featured Program")

    get localized_public_home_path(locale: :en)

    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).not_to include("Featured Program")
  end
end
