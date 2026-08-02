require "net/http"
require "json"

module Notifications
  class WhatsAppProvider
    GRAPH_VERSION = "v23.0".freeze

    def initialize(access_token: ENV["WHATSAPP_ACCESS_TOKEN"],
                   phone_number_id: ENV["WHATSAPP_PHONE_NUMBER_ID"],
                   business_account_id: ENV["WHATSAPP_BUSINESS_ACCOUNT_ID"])
      @access_token = access_token
      @phone_number_id = phone_number_id
      @business_account_id = business_account_id
    end

    def deliver(recipient:, body:, **)
      return failure("configuration_missing", "WhatsApp provider is not configured") if configuration_missing?

      response = request(recipient:, body:)
      parsed = parse_response(response.body)
      return success(parsed, response.code.to_i) if response.is_a?(Net::HTTPSuccess)

      error = parsed.fetch("error", {})
      failure(error["code"].to_s.presence || "provider_error", error["message"].to_s,
              safe_response(parsed), response.code.to_i)
    rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
      failure(e.class.name, "WhatsApp delivery failed")
    end

    private

    def request(recipient:, body:)
      uri = URI("https://graph.facebook.com/#{GRAPH_VERSION}/#{@phone_number_id}/messages")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@access_token}"
      request["Content-Type"] = "application/json"
      request.body = { messaging_product: "whatsapp", recipient_type: "individual", to: recipient,
                       type: "text", text: { preview_url: false, body: } }.to_json
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 20) do |http|
        http.request(request)
      end
    end

    def configuration_missing? = @access_token.blank? || @phone_number_id.blank? || @business_account_id.blank?

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
        "error" => parsed["error"]&.slice("message", "type", "code", "fbtrace_id"),
        "raw_body" => parsed["raw_body"] }
        .compact
    end
  end
end
