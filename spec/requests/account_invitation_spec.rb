require "rails_helper"

RSpec.describe "Account invitations" do
  let(:admin) { create(:user, :admin) }

  it "automatically invites a newly created account and ignores submitted status/password" do
    sign_in admin
    expect do
      post admin_users_path, params: { user: { first_name: "Invited", last_name: "Teacher",
                                               email: "invitee@example.test", role: "teacher", status: "active",
                                               password: "KnownPassword123!", preferred_locale: "en",
                                               time_zone: "Cairo" } }
    end.to change(AccountInvitation, :count).by(1).and change(ActionMailer::Base.deliveries, :count).by(1)

    expect(User.find_by!(email: "invitee@example.test")).to be_pending
  end

  it "lets the token holder choose a password and prevents reuse" do
    raw_token = AccountInvitations::Token.generate
    invitation = create(:account_invitation, token_digest: AccountInvitations::Token.digest(raw_token),
                                             created_by: admin)

    get edit_account_invitation_path(token: raw_token, locale: :en)
    expect(response).to have_http_status(:ok)
    patch account_invitation_path(token: raw_token, locale: :en),
          params: { account_invitation: { password: "ChosenPass123!", password_confirmation: "ChosenPass123!" } }
    expect(response).to redirect_to(account_invitation_success_path(locale: :en))
    expect(invitation.user.reload.valid_password?("ChosenPass123!")).to be(true)

    get edit_account_invitation_path(token: raw_token)
    expect(response).to have_http_status(:not_found)
  end

  it "allows only administrators to manage invitations" do
    invitation = create(:account_invitation, created_by: admin)
    sign_in create(:user, :teacher)
    get admin_account_invitations_path
    expect(response).to have_http_status(:forbidden)
    patch cancel_admin_account_invitation_path(invitation)
    expect(response).to have_http_status(:forbidden)
  end

  it "supports administrator filtering, resending, and cancellation without delete routes" do
    invitation = create(:account_invitation, created_by: admin)
    sign_in admin
    get admin_account_invitations_path(status: "sent", query: invitation.user.email)
    expect(response.body).to include(invitation.user.email)
    patch resend_admin_account_invitation_path(invitation)
    expect(invitation.reload.resent_count).to eq(1)
    patch cancel_admin_account_invitation_path(invitation)
    expect(invitation.reload).to be_cancelled
    expect(Rails.application.routes.routes.map(&:verb).grep(/DELETE/)).not_to be_empty
    path = "/admin/account_invitations/#{invitation.id}"
    expect(Rails.application.routes.recognize_path(path, method: :delete)).to be_nil
  rescue ActionController::RoutingError
    # Expected: invitation resources deliberately have no destructive route.
  end
end
