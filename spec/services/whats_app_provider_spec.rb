require "rails_helper"

RSpec.describe Notifications::WhatsAppProvider do
  subject(:provider) do
    described_class.new(access_token: "secret-access-token", phone_number_id: "phone-id",
                        business_account_id: "business-id", graph_api_version: "v23.0")
  end

  let(:template) do
    Notifications::AccountSetupTemplate.call(display_name: "Amina", email: "amina@example.test",
                                             url_suffix: "raw-invitation-token?locale=ar")
  end

  it "handles successful API responses" do
    stub_response(Net::HTTPOK, 200, '{"messages":[{"id":"wamid.1","message_status":"accepted"}]}')
    result = provider.deliver(recipient: "201001234567", body: nil, template:)
    expect(result).to be_success
    expect(result.provider_message_id).to eq("wamid.1")
  end

  it "sanitizes Meta 4xx responses" do
    stub_response(Net::HTTPBadRequest, 400,
                  '{"error":{"message":"raw-invitation-token","type":"OAuthException","code":131009}}')
    result = provider.deliver(recipient: "201001234567", body: nil, template:)
    expect(result).not_to be_success
    expect(result.http_status).to eq(400)
    expect(result.response.to_s).not_to include("raw-invitation-token")
  end

  it "handles Meta 5xx responses" do
    stub_response(Net::HTTPInternalServerError, 500, '{"error":{"code":2}}')
    result = provider.deliver(recipient: "201001234567", body: nil, template:)
    expect(result).not_to be_success
    expect(result.http_status).to eq(500)
  end

  it "handles network timeouts without logging secrets" do
    allow(Net::HTTP).to receive(:start).and_raise(Timeout::Error, "secret-access-token raw-invitation-token")
    output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(output)
    result = provider.deliver(recipient: "201001234567", body: nil, template:)
    expect(result).not_to be_success
    expect(output.string).not_to include("secret-access-token", "raw-invitation-token")
  ensure
    Rails.logger = original_logger
  end

  def stub_response(response_class, code, body)
    response = response_class.new("1.1", code.to_s, "test")
    response.instance_variable_set(:@read, true)
    response.body = body
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:start).and_yield(http)
    allow(http).to receive(:request).and_return(response)
  end
end
