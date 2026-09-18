require "rails_helper"

RSpec.describe Whatsapp::IngestWebhook do
  subject(:ingest) { described_class.new(payload:).call }

  let(:phone_number_id) { "123456789" }
  let(:value) do
    {
      "messaging_product" => "whatsapp",
      "metadata" => { "phone_number_id" => phone_number_id },
      "contacts" => [{ "wa_id" => "201001234567", "profile" => { "name" => "Student Sender" } }],
      "messages" => [{ "from" => "201001234567", "id" => "wamid.inbound-1",
                       "timestamp" => Time.current.to_i.to_s, "type" => "text",
                       "text" => { "body" => "I need help with my lesson" } }]
    }
  end
  let(:payload) do
    {
      "object" => "whatsapp_business_account",
      "entry" => [{ "changes" => [{ "field" => "messages", "value" => value }] }]
    }
  end

  around do |example|
    original = ENV.fetch("WHATSAPP_PHONE_NUMBER_ID", nil)
    ENV["WHATSAPP_PHONE_NUMBER_ID"] = "123456789"
    example.run
  ensure
    original.nil? ? ENV.delete("WHATSAPP_PHONE_NUMBER_ID") : ENV["WHATSAPP_PHONE_NUMBER_ID"] = original
  end

  it "safely ignores a synthetic non-message value without a phone number ID" do
    value.replace("messaging_product" => "whatsapp")
    allow(Rails.logger).to receive(:info)

    expect { ingest }.not_to change(WhatsappMessage, :count)
    expect(Rails.logger).to have_received(:info)
      .with("Ignoring unsupported WhatsApp webhook value with no messages or statuses")
    expect(WhatsappConversation.count).to be_zero
  end

  it "ingests a real message with the configured phone number ID" do
    expect { ingest }.to change(WhatsappMessage, :count).by(1)

    expect(WhatsappConversation.sole.messages.sole.body).to eq("I need help with my lesson")
  end

  it "ingests a string-keyed payload" do
    expect(payload.keys).to all(be_a(String))

    expect { described_class.new(payload:).call }.to change(WhatsappMessage, :count).by(1)
  end

  it "normalizes and ingests a symbol-keyed payload" do
    symbol_payload = payload.deep_symbolize_keys

    expect { described_class.new(payload: symbol_payload).call }.to change(WhatsappMessage, :count).by(1)
  end

  it "normalizes and ingests ActionController::Parameters" do
    params_payload = ActionController::Parameters.new(payload)

    expect { described_class.new(payload: params_payload).call }.to change(WhatsappMessage, :count).by(1)
  end

  it "ingests the payload shape produced by an Active Job serialization round trip" do
    serialized = ActiveJob::Arguments.serialize([payload])
    stored_arguments = JSON.parse(JSON.generate(serialized))
    job_payload = ActiveJob::Arguments.deserialize(stored_arguments).first

    expect(job_payload.dig("entry", 0, "changes", 0, "value", "metadata", "phone_number_id"))
      .to eq(phone_number_id)
    expect { described_class.new(payload: job_payload).call }.to change(WhatsappMessage, :count).by(1)
  end

  it "rejects a real message with the wrong phone number ID" do
    value["metadata"]["phone_number_id"] = "wrong-id"

    expect { ingest }.to raise_error(SecurityError, "Unexpected WhatsApp phone number ID")
    expect(WhatsappMessage.count).to be_zero
  end

  it "rejects a real message with a missing phone number ID" do
    value.delete("metadata")

    expect { ingest }.to raise_error(SecurityError, "Unexpected WhatsApp phone number ID")
    expect(WhatsappMessage.count).to be_zero
  end

  it "validates a status value and otherwise leaves it unpersisted" do
    value.replace(
      "messaging_product" => "whatsapp",
      "metadata" => { "phone_number_id" => phone_number_id },
      "statuses" => [{ "id" => "wamid.outbound-1", "status" => "delivered" }]
    )

    expect { ingest }.not_to change(WhatsappMessage, :count)
    expect(WhatsappConversation.count).to be_zero
  end

  it "rejects a status value with a missing phone number ID" do
    value.replace(
      "messaging_product" => "whatsapp",
      "statuses" => [{ "id" => "wamid.outbound-1", "status" => "delivered" }]
    )

    expect { ingest }.to raise_error(SecurityError, "Unexpected WhatsApp phone number ID")
  end
end
