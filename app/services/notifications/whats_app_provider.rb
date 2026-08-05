require "net/http"
require "json"

module Notifications
  class WhatsAppProvider
    def initialize(access_token: ENV.fetch("WHATSAPP_ACCESS_TOKEN", nil),
                   phone_number_id: ENV.fetch("WHATSAPP_PHONE_NUMBER_ID", nil),
                   business_account_id: ENV.fetch("WHATSAPP_BUSINESS_ACCOUNT_ID", nil),
                   graph_api_version: ENV.fetch("WHATSAPP_GRAPH_API_VERSION", nil))
      @access_token = access_token
      @phone_number_id = phone_number_id
      @business_account_id = business_account_id
      @graph_api_version = graph_api_version
    end

    def deliver(recipient:, body:, template: nil, **)
      Rails.logger.info("WhatsApp provider called")
      result = delivery_result(recipient:, body:, template:)
      log_response(result)
      result
    rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
      result = failure(e.class.name, "WhatsApp delivery failed")
      log_response(result)
      result
    end

    private

    def delivery_result(recipient:, body:, template:)
      return failure("configuration_missing", "WhatsApp provider is not configured") if configuration_missing?

      perform_delivery(recipient:, body:, template:)
    end

    def perform_delivery(recipient:, body:, template:)
      response = request(recipient:, body:, template:)
      parsed = parse_response(response.body)
      return success(parsed, response.code.to_i) if response.is_a?(Net::HTTPSuccess)

      error = parsed.fetch("error", {})
      failure(error["code"].to_s.presence || "provider_error", "WhatsApp provider rejected the request",
              safe_response(parsed), response.code.to_i)
    end

    def log_response(result)
      details = { success: result.success?, http_status: result.http_status,
                  provider_status: result.provider_status, provider_message_id: result.provider_message_id,
                  error_code: result.error_code }.compact
      Rails.logger.info("WhatsApp provider response #{details.inspect}")
    end

    def request(recipient:, body:, template:)
      uri = URI("https://graph.facebook.com/#{@graph_api_version}/#{@phone_number_id}/messages")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@access_token}"
      request["Content-Type"] = "application/json"
      request.body = outbound_payload(recipient:, body:, template:).to_json
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 20) do |http|
        http.request(request)
      end
    end

    def outbound_payload(recipient:, body:, template:)
      return template_payload(recipient:, template:) if template

      { messaging_product: "whatsapp", recipient_type: "individual", to: recipient,
        type: "text", text: { preview_url: false, body: } }
    end

    def template_payload(recipient:, template:)
      { messaging_product: "whatsapp", recipient_type: "individual", to: recipient,
        type: "template",
        template: {
          name: template.fetch(:name), language: { code: template.fetch(:language_code) },
          components: template.fetch(:components)
        } }
    end

    def configuration_missing?
      @access_token.blank? || @phone_number_id.blank? || @business_account_id.blank? || @graph_api_version.blank?
    end

    def parse_response(body)
      JSON.parse(body)
    rescue JSON::ParserError
      { "raw_body" => body.to_s.first(2_000) }
    end

    def success(parsed, http_status)
      provider_status = parsed.dig("messages", 0, "message_status") || "accepted"
      ProviderResult.new(true, parsed.dig("messages", 0, "id"), safe_response(parsed), http_status,
                         provider_status, nil, nil)
    end

    def failure(code, message, response = {}, http_status = nil)
      ProviderResult.new(false, nil, response, http_status, "failed", code, message)
    end

    def safe_response(parsed)
      { "messaging_product" => parsed["messaging_product"], "messages" => parsed["messages"],
        "error" => parsed["error"]&.slice("type", "code", "fbtrace_id") }
        .compact
    end
  end
end
