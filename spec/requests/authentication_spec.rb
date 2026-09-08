require "rails_helper"

RSpec.describe "Authentication" do
  let(:password) { "SecurePass123!" }

  it "redirects unauthenticated dashboard requests to sign in" do
    get dashboard_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "allows an active user to sign in and sign out" do
    user = create(:user, password:, password_confirmation: password)

    post user_session_path, params: { user: { email: user.email, password: } }
    expect(response).to redirect_to(dashboard_path)

    delete destroy_user_session_path
    expect(response).to redirect_to(root_path)
  end

  it "fails invalid credentials without revealing account details" do
    user = create(:user, password:, password_confirmation: password)

    post user_session_path, params: { user: { email: user.email, password: "incorrect-password" } }

    expect(response).to redirect_to(new_user_session_path(locale: :ar))
    follow_redirect!
    expect(response.body).to include(I18n.t("devise.failure.invalid"))
  end

  %i[pending suspended disabled].each do |status|
    it "rejects a #{status} account with a localized status message" do
      user = create(:user, status, password:, password_confirmation: password)

      post user_session_path, params: { user: { email: user.email, password: } }

      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("devise.failure.#{status}_account"))
    end
  end

  it "renders forgot and reset password pages" do
    get new_user_password_path
    expect(response).to have_http_status(:ok)

    get edit_user_password_path(reset_password_token: "invalid")
    expect(response).to have_http_status(:ok)
  end

  it "handles reset requests with a generic response" do
    user = create(:user)

    expect do
      post user_password_path, params: { user: { email: user.email } }
    end.to change(ActionMailer::Base.deliveries, :count).by(1)

    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:notice]).to eq(I18n.t("devise.passwords.send_paranoid_instructions"))
  end

  it "does not expose public registration routes" do
    expect { Rails.application.routes.recognize_path("/account/sign-up") }
      .to raise_error(ActionController::RoutingError)
  end
end
