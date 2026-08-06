require "rails_helper"

RSpec.describe Notifications::InvitationDelivery do
  let(:admin) { create(:user, :admin) }
  let(:raw_token) { "sensitive-invitation-token" }
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
    AcademySetting.current.update!(whatsapp_notifications_enabled: true, invitation_notifications_enabled: true,
                                   email_notifications_enabled: true)
  end

  def invitation_for(notification_method:, whatsapp_number: "+201001234567")
    user = create(:user, :teacher, :pending, first_name: "Amina", last_name: "Hassan", email: "amina@example.test")
    create(:teacher_profile, user:, whatsapp_number:, notification_method:)
    create(:account_invitation, user:, created_by: admin, token_digest: AccountInvitations::Token.digest(raw_token))
  end

  def deliver(invitation)
    described_class.new(invitation:, token: raw_token, actor: admin).call
  end

  def run_after_commit_callbacks
    callback = nil
    allow(ActiveRecord).to receive(:after_all_transactions_commit) { |&block| callback = block }
    yield
    callback&.call
  end

  it "attempts email only when notification_method is email" do
    invitation = invitation_for(notification_method: "email")
    allow(AccountSetupWhatsAppJob).to receive(:perform_later)

    result = deliver(invitation)

    expect(result.requested).to eq(%w[email])
    expect(result.succeeded).to eq(%w[email])
    expect(result.skipped).to be_empty
    expect(ActionMailer::Base.deliveries).not_to be_empty
    expect(AccountSetupWhatsAppJob).not_to have_received(:perform_later)
  end

  it "attempts whatsapp only when notification_method is whatsapp" do
    invitation = invitation_for(notification_method: "whatsapp")

    result = nil
    run_after_commit_callbacks { result = deliver(invitation) }

    expect(result.requested).to eq(%w[whatsapp])
    expect(result.succeeded).to eq(%w[whatsapp])
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "attempts both channels independently when notification_method is both" do
    invitation = invitation_for(notification_method: "both")

    result = nil
    run_after_commit_callbacks { result = deliver(invitation) }

    expect(result.requested).to eq(%w[email whatsapp])
    expect(result.succeeded).to eq(%w[email whatsapp])
    expect(ActionMailer::Base.deliveries).not_to be_empty
  end

  it "still sends email when whatsapp is disabled" do
    invitation = invitation_for(notification_method: "both")
    ENV["WHATSAPP_ENABLED"] = "false"

    result = deliver(invitation)

    expect(result.succeeded).to eq(%w[email])
    expect(result.skipped).to eq(%w[whatsapp])
    expect(ActionMailer::Base.deliveries).not_to be_empty
  end

  it "still attempts whatsapp when email is disabled" do
    invitation = invitation_for(notification_method: "both")
    AcademySetting.current.update!(email_notifications_enabled: false)

    result = nil
    run_after_commit_callbacks { result = deliver(invitation) }

    expect(result.failed).to eq(%w[email])
    expect(result.succeeded).to eq(%w[whatsapp])
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "skips whatsapp with reason=disabled and logs it without secrets" do
    invitation = invitation_for(notification_method: "whatsapp")
    ENV["WHATSAPP_ENABLED"] = "false"
    output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(output)

    result = deliver(invitation)

    expect(result.skipped).to eq(%w[whatsapp])
    expect(output.string).to include("whatsapp dispatch skipped reason=disabled")
    expect(output.string).not_to include(raw_token, "test-access-token")
  ensure
    Rails.logger = original_logger
  end

  it "skips whatsapp with reason=not_configured when required env vars are missing" do
    invitation = invitation_for(notification_method: "whatsapp")
    ENV.delete("WHATSAPP_PHONE_NUMBER_ID")

    result = deliver(invitation)

    expect(result.skipped).to eq(%w[whatsapp])
  end

  it "skips whatsapp with reason=invalid_number for a blank or malformed number" do
    invitation = invitation_for(notification_method: "whatsapp", whatsapp_number: nil)
    invitation.user.teacher_profile.update_columns(phone_number: nil)

    result = deliver(invitation)

    expect(result.skipped).to eq(%w[whatsapp])
  end

  it "skips whatsapp with reason=url_prefix_mismatch when the configured prefix does not match" do
    invitation = invitation_for(notification_method: "whatsapp")
    ENV["WHATSAPP_ACCOUNT_SETUP_URL_PREFIX"] = "https://attacker.test/account/invitation/"

    result = deliver(invitation)

    expect(result.skipped).to eq(%w[whatsapp])
  end

  it "never logs the raw invitation token, access token, or invitation URL suffix" do
    invitation = invitation_for(notification_method: "both")
    output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(output)

    run_after_commit_callbacks { deliver(invitation) }

    expect(output.string).not_to include(raw_token, "test-access-token")
  ensure
    Rails.logger = original_logger
  end

  it "does not create a whatsapp notification when the channel is not requested" do
    invitation = invitation_for(notification_method: "email")

    deliver(invitation)

    expect(invitation.notifications.where(channel: "whatsapp")).not_to exist
    expect(invitation.notifications.where(channel: "email")).to exist
  end
end
