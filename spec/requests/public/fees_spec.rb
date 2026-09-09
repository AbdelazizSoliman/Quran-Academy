require "rails_helper"

RSpec.describe "Public fees" do
  let(:academy_setting) { create(:academy_setting) }

  before { create(:public_website_setting, academy_setting:) }

  def published_plan(**attributes)
    create(:fee_plan, :published, name: "Internal Monthly Plan", name_ar: "الخطة الشهرية",
                                  name_en: "Monthly Plan", amount: 750, tax_percentage: 23.45, invoice_day: 19,
                                  price_note_en: "Billed monthly", price_note_ar: "تُحصّل شهرياً", **attributes)
  end

  it "lists published fee plans in Arabic with localized content" do
    published_plan

    get public_fees_path(locale: :ar)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<html lang="ar" dir="rtl">')
    expect(response.body).to include("الخطة الشهرية", "تُحصّل شهرياً", "حصص منتظمة")
    expect(response.body).not_to include("Monthly Plan", "Billed monthly")
  end

  it "lists published fee plans in English with localized content" do
    published_plan

    get public_fees_path(locale: :en)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<html lang="en" dir="ltr">')
    expect(response.body).to include("Monthly Plan", "Billed monthly", "Regular lessons")
    expect(response.body).not_to include("الخطة الشهرية")
    expect(response.body).to include(public_trial_path(locale: :en))
  end

  it "omits an unpublished fee plan from the public page" do
    published_plan
    create(:fee_plan, :published, name_en: "Not Published Plan").update!(published: false)

    get public_fees_path(locale: :en)

    expect(response.body).to include("Monthly Plan")
    expect(response.body).not_to include("Not Published Plan")
  end

  it "omits an inactive fee plan even when it is published" do
    published_plan
    create(:fee_plan, :published, :inactive, name_en: "Retired Plan")

    get public_fees_path(locale: :en)

    expect(response.body).not_to include("Retired Plan")
  end

  it "never exposes operational billing mechanics" do
    fee_plan = published_plan

    get public_fees_path(locale: :en)

    expect(response.body).not_to include(fee_plan.public_id, "Internal Monthly Plan", "23.45")
    expect(response.body).not_to include("invoice_day", "tax_percentage", fee_plan.created_by.email)
  end

  it "shows an honest empty state instead of placeholder pricing" do
    get public_fees_path(locale: :en)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("public.fees.empty.title", locale: :en))
  end

  it "follows the disabled website behaviour of the homepage" do
    academy_setting.public_website_setting.update!(enabled: false)
    published_plan

    get public_fees_path(locale: :ar)

    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).to include(I18n.t("public.unavailable.title", locale: :ar))
    expect(response.body).not_to include("الخطة الشهرية")
  end
end
