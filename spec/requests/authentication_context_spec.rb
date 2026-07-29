require "rails_helper"

RSpec.describe "Authentication request context", type: :request do
  let(:password) { "SecurePass123!" }

  it "renders Arabic authentication pages RTL by default" do
    get new_user_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<html lang="ar" dir="rtl">')
    expect(response.body).not_to include("application-sidebar")
  end

  it "renders English authentication pages LTR when explicitly requested" do
    get new_user_session_path(locale: :en)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<html lang="en" dir="ltr">')
  end

  it "ignores unsupported locale parameters" do
    get new_user_session_path(locale: :fr)

    expect(response.body).to include('<html lang="ar" dir="rtl">')
  end

  it "uses the authenticated user locale, time zone, and account navigation" do
    user = create(:user, :teacher, :english_locale, time_zone: "London", password:, password_confirmation: password)
    post user_session_path, params: { user: { email: user.email, password: } }

    get root_path

    expect(response.body).to include('<html lang="en" dir="ltr">')
    expect(response.body).to include('data-time-zone="London"')
    expect(response.body).to include(user.full_name)
    expect(response.body).to include(I18n.t("roles.teacher", locale: :en))
    expect(response.body).to include(destroy_user_session_path)
  end
end
