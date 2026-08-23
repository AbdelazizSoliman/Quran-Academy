require "rails_helper"

RSpec.describe "WhatsApp inbound webhook" do
  let(:app_secret) { "meta-app-secret" }
  let(:verify_token) { "private-webhook-token" }
  let(:phone_number_id) { "123456789" }
  let(:student) { create(:student_profile, whatsapp_number: "+201001234567") }
  let(:payload) do
    {
      object: "whatsapp_business_account",
      entry: [{ changes: [{ field: "messages", value: {
        metadata: { phone_number_id: },
        contacts: [{ wa_id: "201001234567", profile: { name: "Student Sender" } }],
        messages: [{ from: "201001234567", id: "wamid.inbound-1", timestamp: Time.current.to_i.to_s,
                     type: "text", text: { body: "I need help with my lesson" } }]
      } }] }]
    }
  end

  around do |example|
    original = ENV.to_h.slice("WHATSAPP_APP_SECRET", "WHATSAPP_WEBHOOK_VERIFY_TOKEN", "WHATSAPP_PHONE_NUMBER_ID")
    ENV["WHATSAPP_APP_SECRET"] = app_secret
    ENV["WHATSAPP_WEBHOOK_VERIFY_TOKEN"] = verify_token
    ENV["WHATSAPP_PHONE_NUMBER_ID"] = phone_number_id
    example.run
  ensure
    %w[WHATSAPP_APP_SECRET WHATSAPP_WEBHOOK_VERIFY_TOKEN WHATSAPP_PHONE_NUMBER_ID].each do |key|
      original.key?(key) ? ENV[key] = original[key] : ENV.delete(key)
    end
  end

  it "completes Meta webhook verification" do
    get "/webhooks/whatsapp", params: {
      "hub.mode" => "subscribe", "hub.verify_token" => verify_token, "hub.challenge" => "challenge-value"
    }

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("challenge-value")
  end

  it "rejects webhook payloads without a valid Meta signature" do
    post "/webhooks/whatsapp", params: payload.to_json, headers: json_headers("sha256=invalid")

    expect(response).to have_http_status(:unauthorized)
    expect(WhatsappMessage.count).to be_zero
  end

  it "rejects a missing Meta signature" do
    post "/webhooks/whatsapp", params: payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:unauthorized)
    expect(WhatsappMessage.count).to be_zero
  end

  it "filters the webhook envelope from request logs" do
    filtered = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(
      payload.deep_stringify_keys
    )

    expect(filtered["entry"]).to eq("[FILTERED]")
    expect(filtered.to_s).not_to include("I need help with my lesson", "201001234567")
    expect(WhatsappWebhookJob).not_to be_log_arguments
  end

  it "stores, matches, and deduplicates incoming messages" do
    student
    raw = payload.to_json
    signature = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', app_secret, raw)}"

    2.times { post "/webhooks/whatsapp", params: raw, headers: json_headers(signature) }

    expect(response).to have_http_status(:ok)
    conversation = WhatsappConversation.sole
    expect(conversation.contact).to eq(student)
    expect(conversation.unread_count).to eq(1)
    expect(conversation.messages.sole.body).to eq("I need help with my lesson")
  end

  it "queues ingestion before acknowledging a valid webhook" do
    raw = payload.to_json
    signature = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', app_secret, raw)}"

    allow(WhatsappWebhookJob).to receive(:perform_later).and_call_original
    post "/webhooks/whatsapp", params: raw, headers: json_headers(signature)

    expect(WhatsappWebhookJob).to have_received(:perform_later)
    expect(response).to have_http_status(:ok)
  end

  it "leaves an ambiguous phone number unmatched" do
    student
    create(:guardian, whatsapp_number: "+201001234567", phone_number: "+201009999999",
                      preferred_contact_method: "whatsapp")
    raw = payload.to_json
    signature = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', app_secret, raw)}"

    post "/webhooks/whatsapp", params: raw, headers: json_headers(signature)

    expect(response).to have_http_status(:ok)
    expect(WhatsappConversation.sole.contact).to be_nil
  end

  it "shows the conversation to an admin and marks it read" do
    raw = payload.to_json
    signature = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', app_secret, raw)}"
    post "/webhooks/whatsapp", params: raw, headers: json_headers(signature)
    conversation = WhatsappConversation.sole
    sign_in create(:user, :admin)

    get admin_whatsapp_conversations_path
    expect(response.body).to include("Student Sender", "I need help with my lesson")

    get admin_whatsapp_conversation_path(conversation)
    expect(response).to have_http_status(:ok)
    expect(conversation.reload.unread_count).to be_zero
  end

  it "rejects non-admin access to the inbox and conversation URL" do
    conversation = receive_payload
    sign_in create(:user, :staff)

    get admin_whatsapp_conversations_path
    expect(response).to have_http_status(:forbidden)

    get admin_whatsapp_conversation_path(conversation)
    expect(response).to have_http_status(:forbidden)
    patch archive_admin_whatsapp_conversation_path(conversation)
    expect(response).to have_http_status(:forbidden)
    patch reopen_admin_whatsapp_conversation_path(conversation)
    expect(response).to have_http_status(:forbidden)
    expect(conversation.reload.unread_count).to eq(1)
    expect(conversation.status).to eq("open")
  end

  private

  def receive_payload
    raw = payload.to_json
    signature = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', app_secret, raw)}"
    post "/webhooks/whatsapp", params: raw, headers: json_headers(signature)
    WhatsappConversation.sole
  end

  def json_headers(signature)
    { "CONTENT_TYPE" => "application/json", "X-Hub-Signature-256" => signature }
  end
end
