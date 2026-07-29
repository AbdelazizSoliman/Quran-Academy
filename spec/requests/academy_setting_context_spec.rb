require "rails_helper"

RSpec.describe "Academy setting request context" do
  let!(:setting) { AcademySetting.current }

  it "uses the academy locale and zone as unauthenticated fallbacks" do
    setting.update!(default_locale: "en", default_time_zone: "London")

    get new_user_session_path

    expect(response.body).to include('lang="en"', 'dir="ltr"', 'data-time-zone="London"')
  end

  it "keeps authenticated user locale and zone ahead of academy defaults" do
    setting.update!(default_locale: "en", default_time_zone: "London")
    user = create(:user, preferred_locale: "ar", time_zone: "Cairo")
    sign_in user

    get root_path

    expect(response.body).to include('lang="ar"', 'dir="rtl"', 'data-time-zone="Cairo"')
  end

  it "keeps explicit supported UI locales working" do
    setting.update!(default_locale: "ar")

    get ui_path(locale: "en")
    expect(response.body).to include('lang="en"', 'dir="ltr"')
    get ui_path(locale: "ar")
    expect(response.body).to include('lang="ar"', 'dir="rtl"')
  end
end
