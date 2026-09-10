require "rails_helper"

RSpec.describe "Public website production readiness" do
  let(:academy_setting) { create(:academy_setting) }

  before do
    create(:public_website_setting, academy_setting:, public_whatsapp_enabled: true,
                                    whatsapp_cta_enabled: true)
    academy_setting.update!(whatsapp_number: "+201001234567")
  end

  it "provides accessible mobile navigation and preserves locale direction" do
    get localized_public_home_path(locale: :ar)

    expect(response.body).to include('<html lang="ar" dir="rtl">',
                                     I18n.t("public.navigation.mobile_menu", locale: :ar))
    expect(response.body).to include("<details", public_contact_path(locale: :ar))
  end

  it "keeps public conversion CTAs instrumented" do
    get localized_public_home_path(locale: :en)

    expect(response.body).to include('data-analytics-event="trial_cta_click"',
                                     'data-analytics-event="whatsapp_click"')
  end

  it "associates inquiry errors with the form" do
    post public_contact_path(locale: :en), params: {
      public_inquiry: { name: "Amina", email: "invalid", message: "" }
    }

    expect(response.body).to include('id="inquiry-errors"', 'aria-describedby="inquiry-errors"')
  end
end
