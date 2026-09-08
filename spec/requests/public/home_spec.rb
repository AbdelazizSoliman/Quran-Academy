require "rails_helper"

RSpec.describe "Public homepage" do
  let(:academy_setting) do
    create(:academy_setting, contact_email: "hello@khadijah.test", contact_phone: "+201111111111",
                             whatsapp_number: "+201222222222")
  end

  it "serves the Arabic root with RTL without creating settings" do
    create(:public_website_setting, academy_setting:)

    expect { get root_path }.not_to change(PublicWebsiteSetting, :count)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<html lang="ar" dir="rtl">')
    expect(response.body).to include("أكاديمية خديجه")
    expect(response.body).not_to include("sidebar")
  end

  it "serves stable Arabic and English locale routes" do
    create(:public_website_setting, academy_setting:)

    get localized_public_home_path(locale: :ar)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<html lang="ar" dir="rtl">')

    get localized_public_home_path(locale: :en)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<html lang="en" dir="ltr">')
    expect(response.body).to include("Khadijah Academy")
  end

  it "returns a controlled unavailable response when disabled" do
    create(:public_website_setting, academy_setting:, enabled: false)

    get root_path

    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).to include(I18n.t("public.unavailable.title", locale: :ar))
    expect(response.body).to include(new_user_session_path(locale: :ar))
  end

  it "does not create a setting when none exists" do
    academy_setting

    expect { get root_path }.not_to change(PublicWebsiteSetting, :count)
    expect(response).to have_http_status(:service_unavailable)
  end

  it "exposes contact values only when their visibility flags are enabled" do
    public_setting = create(:public_website_setting, academy_setting:, public_email_enabled: true)

    get localized_public_home_path(locale: :en)
    expect(response.body).to include("hello@khadijah.test")
    expect(response.body).not_to include("+201111111111", "+201222222222")

    public_setting.update!(public_email_enabled: false, public_phone_enabled: true, public_whatsapp_enabled: true)
    get localized_public_home_path(locale: :en)
    expect(response.body).not_to include("hello@khadijah.test")
    expect(response.body).to include("+201111111111")
    expect(response.body).to include("https://wa.me/201222222222")
  end

  it "keeps login available while the public website is disabled" do
    create(:public_website_setting, academy_setting:, enabled: false)

    get new_user_session_path

    expect(response).to have_http_status(:ok)
  end
end
