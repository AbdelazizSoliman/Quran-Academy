require "rails_helper"

RSpec.describe "Dashboard" do
  it "loads the application home page in Arabic RTL by default" do
    sign_in create(:user, :arabic_locale)

    I18n.with_locale(:ar) do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<html lang="ar" dir="rtl">')
      expect(response.body).to include(I18n.t("app.name"))
      expect(response.body).to include('data-component="stat-card"')
    end
  end

  it "renders English as LTR when the locale changes" do
    sign_in create(:user, :english_locale)

    I18n.with_locale(:en) do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<html lang="en" dir="ltr">')
      expect(response.body).to include(I18n.t("navigation.coming_soon"))
      expect(response.body).not_to include("translation missing")
    end
  end
end
