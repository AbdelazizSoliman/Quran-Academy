require "rails_helper"

RSpec.describe "Public programs" do
  let(:academy_setting) { create(:academy_setting) }

  before { create(:public_website_setting, academy_setting:) }

  def published_program(**attributes)
    create(:program, :published, slug_ar: "أساسيات-التلاوة", slug_en: "recitation-foundations",
                                 name_ar: "أساسيات التلاوة", name_en: "Recitation Foundations",
                                 short_description_ar: "بداية هادئة للتلاوة",
                                 short_description_en: "A calm start to recitation", **attributes)
  end

  it "lists published programs in Arabic with RTL markup" do
    published_program

    get public_programs_path(locale: :ar)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<html lang="ar" dir="rtl">')
    expect(response.body).to include("أساسيات التلاوة", "بداية هادئة للتلاوة")
    expect(response.body).not_to include("Recitation Foundations")
  end

  it "lists published programs in English with LTR markup" do
    published_program

    get public_programs_path(locale: :en)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<html lang="en" dir="ltr">')
    expect(response.body).to include("Recitation Foundations", "A calm start to recitation")
    expect(response.body).not_to include("أساسيات التلاوة")
  end

  it "hides unpublished and inactive programs from the index" do
    published = published_program
    create(:program, :active, name_en: "Hidden Draft Program")
    create(:program, :published, name_en: "Deactivated Program").update!(status: "inactive")

    get public_programs_path(locale: :en)

    expect(response.body).to include(published.name_en)
    expect(response.body).not_to include("Hidden Draft Program", "Deactivated Program")
  end

  it "does not expose an empty program index to an anonymous visitor" do
    get public_programs_path(locale: :en)

    expect(response).to have_http_status(:not_found)
  end

  it "does not expose an empty program index to an authenticated non-admin" do
    sign_in create(:user, :student)

    get public_programs_path(locale: :en)

    expect(response).to have_http_status(:not_found)
  end

  it "redirects an admin from an empty public index to program publishing" do
    sign_in create(:user, :admin)

    get public_programs_path(locale: :en)

    expect(response).to redirect_to(admin_website_programs_path)
  end

  it "serves a program detail page through its locale slug" do
    published_program

    get public_program_path(locale: :en, slug: "recitation-foundations")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Recitation Foundations")

    get public_program_path(locale: :ar, slug: "أساسيات-التلاوة")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("أساسيات التلاوة")
  end

  it "never resolves a slug belonging to the other locale" do
    published_program

    get public_program_path(locale: :en, slug: "أساسيات-التلاوة")
    expect(response).to have_http_status(:not_found)

    get public_program_path(locale: :ar, slug: "recitation-foundations")
    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 for an unpublished program" do
    published_program.update!(published: false)

    get public_program_path(locale: :en, slug: "recitation-foundations")

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include(I18n.t("public.programs.not_found.title", locale: :en))
  end

  it "returns 404 for an inactive program even when published" do
    published_program.update!(status: "inactive")

    get public_program_path(locale: :en, slug: "recitation-foundations")

    expect(response).to have_http_status(:not_found)
  end

  it "cannot be reached by guessing database or operational identifiers" do
    program = published_program

    [program.id.to_s, program.public_id, program.code].each do |identifier|
      get public_program_path(locale: :en, slug: identifier)
      expect(response).to have_http_status(:not_found)
    end
  end

  it "never renders operational or audit data on public program pages" do
    program = published_program(internal_notes: "Do not publish this internal note")

    get public_program_path(locale: :en, slug: "recitation-foundations")

    expect(response.body).not_to include("Do not publish this internal note", program.public_id, program.code)
    expect(response.body).not_to include(program.created_by.email, "created_by", "internal_notes")
  end

  it "follows the disabled website behaviour of the homepage" do
    academy_setting.public_website_setting.update!(enabled: false)
    published_program

    get public_programs_path(locale: :en)
    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).to include(I18n.t("public.unavailable.title", locale: :en))
    expect(response.body).not_to include("Recitation Foundations")

    get public_program_path(locale: :en, slug: "recitation-foundations")
    expect(response).to have_http_status(:service_unavailable)
  end
end
