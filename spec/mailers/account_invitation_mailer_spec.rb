require "rails_helper"

RSpec.describe AccountInvitationMailer do
  it "renders a localized invitation without a password" do
    invitation = create(:account_invitation, user: create(:user, :pending, :english_locale))
    mail = described_class.with(invitation:, token: "raw-secure-token").invitation_email

    expect(mail.to).to eq([invitation.user.email])
    expect(mail.body.encoded).to include("raw-secure-token")
    expect(mail.body.encoded).not_to include("temporary password")
    expect(mail.subject).to include(AcademySetting.current.academy_name)
  end
end
