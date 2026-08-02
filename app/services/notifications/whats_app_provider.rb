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

    def deliver(recipient:, body:, template: nil, **)
      Rails.logger.info("WhatsApp provider called")
      result = if configuration_missing?
                 failure("configuration_missing", "WhatsApp provider is not configured")
               else
                 perform_delivery(recipient:, body:, template:)
               end
      log_response(result)
      result
    rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
      result = failure(e.class.name, "WhatsApp delivery failed")
      log_response(result)
      result
    end

    private

    def perform_delivery(recipient:, body:, template:)
      response = request(recipient:, body:, template:)
      parsed = parse_response(response.body)
      return success(parsed, response.code.to_i) if response.is_a?(Net::HTTPSuccess)

      error = parsed.fetch("error", {})
      failure(error["code"].to_s.presence || "provider_error", error["message"].to_s,
              safe_response(parsed), response.code.to_i)
    end

    def log_response(result)
      details = { success: result.success?, http_status: result.http_status,
                  provider_status: result.provider_status, provider_message_id: result.provider_message_id,
                  error_code: result.error_code, error_message: result.error_message,
                  response: result.response }.compact
      Rails.logger.info("WhatsApp provider response #{details.inspect}")
    end

    def request(recipient:, body:, template:)
      uri = URI("https://graph.facebook.com/#{GRAPH_VERSION}/#{@phone_number_id}/messages")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@access_token}"
      request["Content-Type"] = "application/json"
      payload = outbound_payload(recipient:, body:, template:)
      request.body = payload.to_json
      log_outbound_payload(payload)
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
          components: [{ type: "body", parameters: template.fetch(:parameters) }]
        } }
    end

    def log_outbound_payload(payload)
      safe_payload = payload.deep_dup
      safe_payload[:to] = mask_phone(payload[:to])
      redact_urls!(safe_payload)
      diagnostic = {
        endpoint: "/<PHONE_NUMBER_ID>/messages", payload: safe_payload,
        template_name: payload.dig(:template, :name), language_code: payload.dig(:template, :language, :code),
        message_type: payload[:type], invitation_url_included: payload.to_s.match?(%r{https?://\S+}),
        invitation_url_as_template_parameter: template_url_parameter?(payload)
      }
      Rails.logger.info("WhatsApp outbound payload #{diagnostic.inspect}")
    end

    def redact_urls!(payload)
      payload[:text][:body] = redact(payload.dig(:text, :body)) if payload[:text]
      payload.dig(:template, :components)&.each do |component|
        component[:parameters].each { |parameter| parameter[:text] = redact(parameter[:text]) }
      end
    end

    def redact(value) = value.to_s.gsub(%r{https?://\S+}, "[INVITATION_URL_REDACTED]")

    def template_url_parameter?(payload)
      payload.dig(:template, :components)&.any? do |component|
        component[:parameters].any? { |parameter| parameter[:text].to_s.match?(%r{https?://\S+}) }
      end || false
    end

    def mask_phone(value)
      digits = value.to_s
      "#{'*' * [digits.length - 4, 0].max}#{digits.last(4)}"
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
