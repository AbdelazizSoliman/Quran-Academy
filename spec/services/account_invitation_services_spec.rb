require "rails_helper"

RSpec.describe "Account invitation services" do
  let(:admin) { create(:user, :admin) }

  it "creates a digest-only invitation and sends it" do
    user = create(:user, :pending)

    expect do
      result = AccountInvitations::CreateAndSend.new(user:, actor: admin).call
      expect(result.invitation.token_digest).to eq(AccountInvitations::Token.digest(result.token))
      expect(result.invitation).to be_sent
    end.to change(ActionMailer::Base.deliveries, :count).by(1)
                                                        .and change(AccountInvitationEvent, :count).by(2)
  end

  it "rotates the token and increments resends" do
    invitation = create(:account_invitation, created_by: admin)
    old_digest = invitation.token_digest
    result = AccountInvitations::Resend.new(invitation:, actor: admin).call

    expect(invitation.reload.token_digest).not_to eq(old_digest)
    expect(invitation.resent_count).to eq(1)
    expect(result.token).to be_present
  end

  it "accepts once, activates the user, and records request context" do
    invitation = create(:account_invitation, created_by: admin)
    AccountInvitations::Accept.new(invitation:, password: "NewSecure123!",
                                   password_confirmation: "NewSecure123!", ip: "192.0.2.4",
                                   user_agent: "RSpec").call

    expect(invitation.reload).to be_accepted
    expect(invitation.user.reload).to be_active
    expect(invitation.accepted_ip).to eq("192.0.2.4")
  end

  it "expires an old invitation without activating its user" do
    invitation = create(:account_invitation, expires_at: 1.minute.ago, created_by: admin)
    AccountInvitations::Accept.new(invitation:, password: "NewSecure123!",
                                   password_confirmation: "NewSecure123!", ip: nil, user_agent: nil).call

    expect(invitation.reload).to be_expired
    expect(invitation.user.reload).to be_pending
  end

  it "cancels an unused invitation" do
    invitation = create(:account_invitation, created_by: admin)
    AccountInvitations::Cancel.new(invitation:, actor: admin).call
    expect(invitation.reload).to be_cancelled
  end
end
