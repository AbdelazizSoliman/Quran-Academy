require "rails_helper"

RSpec.describe Admin::Onboarding::CreateTeacher do
  let(:admin) { create(:user, :admin) }
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

  def attributes(notification_method:)
    {
      first_name: "Dakota", last_name: "Evans", email: "dakota.evans@example.test",
      display_name: "Dakota Evans", phone_number: "+201001234567", whatsapp_number: "+201001234567",
      notification_method:, message_language: "ar", employment_status: "candidate",
      workload_percentage: 22, on_leave: false, work_days: [], compensation_unit: "hourly",
      default_lesson_rate: 40, monthly_salary: 0, compensation_currency: "EGP",
      mid_period_previous_dues: false, engagement_type: "contractor", joined_on: Date.current
    }
  end

  def run_after_commit_callbacks
    callbacks = []
    allow(ActiveRecord).to receive(:after_all_transactions_commit) { |&block| callbacks << block }
    yield
    callbacks.each(&:call)
  end

  it "sends both email and WhatsApp when the teacher requests both, matching the reported bug scenario" do
    provider = instance_double(Notifications::WhatsAppProvider)
    success = Notifications::ProviderResult.new(true, "wamid.dakota", {}, 200, "accepted", nil, nil)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(success)

    profile = nil
    run_after_commit_callbacks do
      profile = described_class.new(actor: admin, attributes: attributes(notification_method: "both")).call
    end

    expect(profile).to be_persisted
    expect(profile.notification_method).to eq("both")

    invitation = profile.user.account_invitation
    expect(ActionMailer::Base.deliveries).not_to be_empty
    expect(invitation.notifications.where(channel: "email")).to exist
    expect(invitation.notifications.where(channel: "whatsapp")).to exist
    expect(invitation.notifications.find_by(channel: "whatsapp")).to be_sent
    expect(invitation.reload).to be_sent
  end

  it "creates only a WhatsApp notification when the teacher requests WhatsApp only" do
    provider = instance_double(Notifications::WhatsAppProvider)
    success = Notifications::ProviderResult.new(true, "wamid.dakota", {}, 200, "accepted", nil, nil)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(success)

    profile = nil
    run_after_commit_callbacks do
      profile = described_class.new(actor: admin, attributes: attributes(notification_method: "whatsapp")).call
    end

    invitation = profile.user.account_invitation
    expect(ActionMailer::Base.deliveries).to be_empty
    expect(invitation.notifications.where(channel: "email")).not_to exist
    expect(invitation.notifications.where(channel: "whatsapp")).to exist
    expect(invitation.reload).to be_sent
  end

  it "keeps the invitation pending until the after-commit WhatsApp attempt completes" do
    provider = instance_double(Notifications::WhatsAppProvider)
    success = Notifications::ProviderResult.new(true, "wamid.dakota", {}, 200, "accepted", nil, nil)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(success)

    callbacks = []
    allow(ActiveRecord).to receive(:after_all_transactions_commit) { |&block| callbacks << block }
    profile = described_class.new(actor: admin, attributes: attributes(notification_method: "whatsapp")).call
    invitation = profile.user.account_invitation

    expect(invitation.reload).to be_pending
    callbacks.each(&:call)
    expect(invitation.reload).to be_sent
  end

  it "keeps teacher creation committed and email successful when WhatsApp delivery fails" do
    provider = instance_double(Notifications::WhatsAppProvider)
    failure = Notifications::ProviderResult.new(false, nil, {}, 500, "failed", "provider_error",
                                                "WhatsApp provider rejected the request")
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(failure)
    admin # created eagerly so only the teacher's user counts inside the block below

    profile = nil
    expect do
      run_after_commit_callbacks do
        profile = described_class.new(actor: admin, attributes: attributes(notification_method: "both")).call
      end
    end.to change(User, :count).by(1).and change(TeacherProfile, :count).by(1)

    expect(profile).to be_persisted
    invitation = profile.user.account_invitation
    expect(ActionMailer::Base.deliveries).not_to be_empty
    expect(invitation.reload).to be_sent
    expect(invitation.notifications.find_by(channel: "whatsapp")).to be_failed
  end

  it "keeps teacher creation committed when WhatsApp is disabled entirely" do
    ENV["WHATSAPP_ENABLED"] = "false"

    profile = described_class.new(actor: admin, attributes: attributes(notification_method: "both")).call

    expect(profile).to be_persisted
    invitation = profile.user.account_invitation
    expect(ActionMailer::Base.deliveries).not_to be_empty
    expect(invitation.notifications.where(channel: "whatsapp")).not_to exist
    expect(invitation.reload).to be_sent
  end
end
