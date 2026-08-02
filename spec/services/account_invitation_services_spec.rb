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

  it "keeps a created invitation pending when delivery fails" do
    delivery = instance_double(ActionMailer::MessageDelivery)
    mailer = instance_double(AccountInvitationMailer, invitation_email: delivery)
    allow(AccountInvitationMailer).to receive(:with).and_return(mailer)
    allow(delivery).to receive(:deliver_now).and_raise(Resend::Error.new("delivery failed", 500))

    user = create(:user, :pending)
    expect do
      result = AccountInvitations::CreateAndSend.new(user:, actor: admin).call
      expect(result.invitation).to be_pending
    end.to change(AccountInvitation, :count).by(1).and change(AccountInvitationEvent, :count).by(1)
  end

  it "sends one invitation token through email and WhatsApp with an identical URL" do
    setting = AcademySetting.current
    setting.update!(invitation_delivery_mode: "email_and_whatsapp", whatsapp_notifications_enabled: true)
    user = create(:user, :teacher, :pending, preferred_locale: "en")
    create(:teacher_profile, user:, whatsapp_number: "+201001234567")
    provider = instance_double(Notifications::WhatsAppProvider)
    result = Notifications::ProviderResult.new(true, "wamid.invitation", {}, 200, "accepted", nil, nil)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(result)

    service_result = AccountInvitations::CreateAndSend.new(user:, actor: admin).call
    invitation_url = AccountInvitations::UrlBuilder.call(token: service_result.token, locale: "en")

    digest = AccountInvitations::Token.digest(service_result.token)
    expect(service_result.invitation.token_digest).to eq(digest)
    expect(ActionMailer::Base.deliveries.last.text_part.body.decoded).to include(invitation_url)
    expect(provider).to have_received(:deliver).with(hash_including(body: include(invitation_url)))
  end

  it "retains a failed WhatsApp invitation for an administrator retry" do
    AcademySetting.current.update!(invitation_delivery_mode: "whatsapp_only",
                                   whatsapp_notifications_enabled: true)
    user = create(:user, :teacher, :pending)

    result = AccountInvitations::CreateAndSend.new(user:, actor: admin).call
    notification = result.invitation.notifications.last

    expect(result.invitation).to be_pending
    expect(notification).to be_failed
    expect(notification.delivery_payload_ciphertext).to be_present
    expect(notification.message_snapshot).to eq(I18n.t("notifications.secure_link_omitted"))
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
