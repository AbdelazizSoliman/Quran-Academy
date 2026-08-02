module Notifications
  class EmailProvider
    def deliver(recipient:, subject:, body:, mailer: nil)
      delivery = (mailer || NotificationMailer.with(recipient:, subject:, body:).delivery).deliver_now
      message_id = provider_message_id(delivery)
      http_status = delivery.status.to_i if delivery.respond_to?(:status) && delivery.status.present?
      response = { "provider" => "resend", "accepted" => true, "message_id" => message_id,
                   "http_status" => http_status }.compact
      ProviderResult.new(true, message_id, response, http_status, "accepted", nil, nil)
    rescue StandardError => e
      log_delivery_error(e)
      ProviderResult.new(false, nil, {}, response_status(e), "failed", e.class.name, e.message)
    end

    private

    def provider_message_id(delivery)
      return delivery.message_id if delivery.respond_to?(:message_id) && delivery.message_id.present?
      return delivery.id if delivery.respond_to?(:id) && delivery.id.present?

      delivery["id"] if delivery.respond_to?(:[])
    end

    def log_delivery_error(error)
      Rails.logger.error("Resend delivery failed")
      Rails.logger.error("Class: #{error.class}")
      Rails.logger.error("Message: #{error.message}")
      log_response(error)
      identifier = request_id(error)
      Rails.logger.error("Request ID: #{identifier}") if identifier.present?
      Rails.logger.error(Array(error.backtrace).first(10).join("\n"))
    end

    def log_response(error)
      response = error_response(error)
      status = response_status(error)
      headers = response_value(response, :headers) || response_value(error, :headers)
      body = response_value(response, :body) || response_value(error, :body)
      return if status.nil? && headers.blank? && body.blank? && response.blank?

      Rails.logger.error("Status: #{status.inspect}")
      Rails.logger.error("Headers: #{headers.inspect}")
      Rails.logger.error("Body: #{body.inspect}")
    end

    def response_status(error)
      response = error_response(error)
      value = response_value(response, :status) || response_value(response, :status_code) ||
              response_value(error, :status) || response_value(error, :status_code)
      Integer(value, exception: false)
    end

    def request_id(error)
      return error.request_id if error.respond_to?(:request_id) && error.request_id.present?

      response = error_response(error)
      direct = response_value(response, :request_id)
      return direct if direct.present?

      headers = response_value(response, :headers)
      headers&.[]("x-request-id") || headers&.[]("request-id") || headers&.[](:request_id)
    end

    def response_value(response, key)
      return if response.nil?
      return response.public_send(key) if response.respond_to?(key)
      return unless response.respond_to?(:[])

      response[key] || response[key.to_s]
    rescue StandardError
      nil
    end

    def error_response(error)
      error.response if error.respond_to?(:response)
    rescue StandardError
      nil
    end
  end
end
