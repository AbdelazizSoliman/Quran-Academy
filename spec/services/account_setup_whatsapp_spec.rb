require "rails_helper"

RSpec.describe "WhatsApp account setup" do
  let(:admin) { create(:user, :admin) }
  let(:user) do
    create(:user, :teacher, :pending, first_name: "Amina", last_name: "Hassan", email: "amina@example.test")
  end
  let!(:profile) do
    create(:teacher_profile, user:, whatsapp_number: "+20 100-123-4567", notification_method: "both")
  end
  let(:raw_token) { "sensitive-invitation-token" }
  let(:invitation) do
    create(:account_invitation, user:, created_by: admin,
                                token_digest: AccountInvitations::Token.digest(raw_token))
  end
  let(:configuration) do
    {
      "WHATSAPP_ENABLED" => "true",
      "WHATSAPP_ACCESS_TOKEN" => "test-access-token",
      "WHATSAPP_PHONE_NUMBER_ID" => "test-phone-id",
      "WHATSAPP_BUSINESS_ACCOUNT_ID" => "test-business-id",
      "WHATSAPP_GRAPH_API_VERSION" => "v23.0",
      "WHATSAPP_ACCOUNT_SETUP_TEMPLATE" => "quran_account_setup",
      "WHATSAPP_ACCOUNT_SETUP_LANGUAGE" => "en_US",
      "WHATSAPP_ACCOUNT_SETUP_URL_PREFIX" => "http://example.com/account/invitation/"
    }
  end

  around do |example|
    previous = configuration.keys.index_with { |key| ENV.fetch(key, nil) }
    configuration.each { |key, value| ENV[key] = value }
    example.run
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  before do
    AcademySetting.current.update!(whatsapp_notifications_enabled: true,
                                   invitation_notifications_enabled: true,
                                   invitation_delivery_mode: "email_and_whatsapp")
  end

  it "registers synchronous provider delivery for after commit while preserving email delivery" do
    callbacks = []
    allow(ActiveRecord).to receive(:after_all_transactions_commit) { |&block| callbacks << block }
    provider = instance_double(Notifications::WhatsAppProvider)
    success = Notifications::ProviderResult.new(true, "wamid.account", {}, 200, "accepted", nil, nil)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(success)

    result = AccountInvitations::CreateAndSend.new(user:, actor: admin).call

    expect(result.invitation.reload).to be_pending
    expect(ActionMailer::Base.deliveries).to be_empty
    callbacks.each(&:call)
    expect(result.invitation.reload).to be_sent
    expect(ActionMailer::Base.deliveries).not_to be_empty
    expect(result.invitation.notifications.find_by(channel: "whatsapp")).to be_sent
  end

  it "builds the exact approved template payload with name, email, then suffix-only URL button" do
    template = Notifications::AccountSetupTemplate.call(
      display_name: user.full_name, email: user.email, url_suffix: "abc123?locale=ar"
    )
    payload = Notifications::WhatsAppProvider.new.send(
      :outbound_payload, recipient: "201001234567", body: nil, template:
    )

    expect(payload).to eq(
      messaging_product: "whatsapp", recipient_type: "individual", to: "201001234567", type: "template",
      template: {
        name: "quran_account_setup", language: { code: "en_US" },
        components: [
          { type: "body", parameters: [
            { type: "text", text: "Amina Hassan" },
            { type: "text", text: "amina@example.test" }
          ] },
          { type: "button", sub_type: "url", index: "0",
            parameters: [{ type: "text", text: "abc123?locale=ar" }] }
        ]
      }
    )
    expect(payload.dig(:template, :components, 1, :parameters, 0, :text)).not_to start_with("http")
  end

  %w[en en_US].each do |language|
    it "accepts #{language} for the account setup template and passes it to Meta" do
      ENV["WHATSAPP_ACCOUNT_SETUP_LANGUAGE"] = language

      expect(Notifications::WhatsappConfiguration).to be_configured
      template = Notifications::AccountSetupTemplate.call(
        display_name: user.full_name, email: user.email, url_suffix: "abc123"
      )

      expect(template[:language_code]).to eq(language)
    end
  end

  it "preserves an encoded locale query while extracting only the dynamic suffix" do
    suffix = Notifications::AccountSetupUrlSuffix.call(
      invitation_url: "http://example.com/account/invitation/abc123?locale=ar%2DEG"
    )
    expect(suffix).to eq("abc123?locale=ar%2DEG")
  end

  it "rejects prefix mismatches and malformed URLs" do
    mismatch = Notifications::AccountSetupUrlSuffix.call(
      invitation_url: "https://attacker.test/account/invitation/abc123?locale=ar"
    )
    malformed = Notifications::AccountSetupUrlSuffix.call(invitation_url: "http://[invalid")
    expect(mismatch).to be_nil
    expect(malformed).to be_nil
  end

  it "sends once for an invitation token and is idempotent on retry" do
    provider = instance_double(Notifications::WhatsAppProvider)
    success = Notifications::ProviderResult.new(true, "wamid.account", {}, 200, "accepted", nil, nil)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(success)
    service = described_delivery

    expect { service.call }.to change(Notification, :count).by(1)
    expect { service.call }.not_to change(Notification, :count)
    expect(provider).to have_received(:deliver).once.with(
      recipient: "201001234567", subject: nil, body: "account setup template",
      template: hash_including(name: "quran_account_setup", language_code: "en_US")
    )
  end

  it "creates a new delivery after an explicit resend rotates the token" do
    provider = instance_double(Notifications::WhatsAppProvider)
    success = Notifications::ProviderResult.new(true, "wamid.account", {}, 200, "accepted", nil, nil)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(success)
    described_delivery.call
    replacement = "replacement-sensitive-token"
    invitation.update!(token_digest: AccountInvitations::Token.digest(replacement),
                       expires_at: 2.days.from_now, status: "sent")

    expect do
      Notifications::AccountSetupDelivery.new(invitation:, actor: admin, token: replacement).call
    end.to change(Notification.where(channel: "whatsapp"), :count).by(1)
  end

  it "skips disabled, missing configuration, and invalid phone states" do
    ENV["WHATSAPP_ENABLED"] = "false"
    expect(described_delivery.call).to be_nil
    ENV["WHATSAPP_ENABLED"] = "true"
    ENV.delete("WHATSAPP_PHONE_NUMBER_ID")
    expect(described_delivery.call).to be_nil
    ENV["WHATSAPP_PHONE_NUMBER_ID"] = "test-phone-id"
    profile.update!(whatsapp_number: "invalid", phone_number: "invalid")
    expect(described_delivery.call).to be_nil
    expect(Notification.where(channel: "whatsapp")).to be_empty
  end

  it "skips template configuration that differs from the approved mapping" do
    ENV["WHATSAPP_ACCOUNT_SETUP_LANGUAGE"] = "not-a-meta-code"
    expect(described_delivery.call).to be_nil
    ENV["WHATSAPP_ACCOUNT_SETUP_LANGUAGE"] = "en_US"
    ENV["WHATSAPP_ACCOUNT_SETUP_TEMPLATE"] = "another_template"
    expect(described_delivery.call).to be_nil
    expect(Notification.where(channel: "whatsapp")).to be_empty
  end

  it "keeps user creation and email successful when WhatsApp fails" do
    provider = instance_double(Notifications::WhatsAppProvider)
    failure = Notifications::ProviderResult.new(false, nil, {}, 500, "failed", "provider_error",
                                                "WhatsApp provider rejected the request")
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(failure)

    invitation
    expect { described_delivery.call }.not_to change(User, :count)
    expect(user).to be_persisted
    expect(invitation.notifications.last).to be_failed

    another = create(:user, :pending)
    expect { AccountInvitations::CreateAndSend.new(user: another, actor: admin).call }
      .to change(ActionMailer::Base.deliveries, :count).by(1)
  end

  it "does not put invitation or access tokens in logs" do
    provider = instance_double(Notifications::WhatsAppProvider)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_raise(StandardError, "#{raw_token} test-access-token")
    output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(output)
    described_delivery.call
    expect(output.string).not_to include(raw_token, "test-access-token")
  ensure
    Rails.logger = original_logger
  end

  def described_delivery
    Notifications::AccountSetupDelivery.new(invitation:, actor: admin, token: raw_token)
  end
end
