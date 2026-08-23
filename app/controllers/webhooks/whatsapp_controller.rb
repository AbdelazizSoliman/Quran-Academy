module Webhooks
  class WhatsappController < ActionController::API
    rescue_from JSON::ParserError, with: :bad_payload
    rescue_from SecurityError, with: :rejected_payload
    rescue_from StandardError, with: :failed_payload

    def verify
      token = ENV.fetch("WHATSAPP_WEBHOOK_VERIFY_TOKEN", nil)
      return head :service_unavailable if token.blank?

      if params["hub.mode"] == "subscribe" && secure?(params["hub.verify_token"].to_s, token)
        render plain: params["hub.challenge"].to_s, status: :ok
      else
        head :forbidden
      end
    end

    def receive
      return head :service_unavailable unless webhook_secret?
      return head :unauthorized unless valid_signature?(@webhook_secret)

      WhatsappWebhookJob.perform_later(JSON.parse(request.raw_post))
      head :ok
    end

    private

    def valid_signature?(secret)
      supplied = request.headers["X-Hub-Signature-256"].to_s
      expected = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, request.raw_post)}"
      secure?(supplied, expected)
    end

    def webhook_secret?
      @webhook_secret = ENV.fetch("WHATSAPP_APP_SECRET", nil)
      @webhook_secret.present?
    end

    def secure?(supplied, expected)
      supplied.bytesize == expected.bytesize && ActiveSupport::SecurityUtils.secure_compare(supplied, expected)
    end

    def bad_payload(*) = head(:bad_request)

    def rejected_payload(error)
      Rails.logger.warn("Rejected WhatsApp webhook: #{error.class}")
      head :forbidden
    end

    def failed_payload(error)
      Rails.logger.error("WhatsApp webhook failed exception=#{error.class}")
      head :internal_server_error
    end
  end
end
