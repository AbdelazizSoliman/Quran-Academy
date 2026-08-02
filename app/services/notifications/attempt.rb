module Notifications
  class Attempt
    def initialize(notification:, actor:, recipient_address: nil, delivery_body: nil, provider_options: {})
      @notification = notification
      @actor = actor
      @recipient_address = recipient_address
      @delivery_body = delivery_body
      @provider_options = provider_options
    end

    def call
      return invalid(:forbidden) unless authorized?
      return invalid(:already_sent) if @notification.sent? || @notification.delivered?
      return invalid(:not_retryable) if @notification.attempt_count.positive? && !@notification.failed?
      return invalid(:fresh_invitation_required) if invitation_retry_without_token?

      address = @recipient_address || resolve_address
      return invalid(:missing_recipient) if address.blank?

      attempt = mark_attempting!(address)
      result = provider.deliver(recipient: address, subject: @notification.subject,
                                body: @delivery_body || @notification.message_snapshot, **@provider_options)
      result.success? ? mark_sent!(attempt, result) : mark_failed!(attempt, result)
      @notification
    rescue ActiveRecord::StaleObjectError
      invalid(:stale_record)
    end

    private

    def authorized?
      return false unless @actor.active?
      return @actor.admin? if @notification.attempt_count.positive?

      @actor.admin? || @notification.actor_id == @actor.id
    end
    def invitation_retry_without_token?
      @notification.notification_type == "account_invitation" && @delivery_body.blank?
    end

    def mark_attempting!(address)
      Notification.transaction do
        now = Time.current
        event_type = @notification.retry_count.positive? || @notification.failed? ? "retried" : "attempted"
        previous = @notification.status
        retry_increment = @notification.first_attempted_at? ? 1 : 0
        @notification.update!(status: "sending", first_attempted_at: @notification.first_attempted_at || now,
                              last_attempted_at: now, attempt_count: @notification.attempt_count + 1,
                              retry_count: @notification.retry_count + retry_increment,
                              failure_code: nil, failure_reason: nil, failed_at: nil)
        event!(event_type, previous, "sending")
        @notification.attempts.create!(actor: @actor, attempt_number: @notification.attempt_count,
                                       provider: provider_name, status: "sending",
                                       recipient_address_masked: mask(address),
                                       request_fingerprint: request_fingerprint(address), attempted_at: now)
      end
    end

    def mark_sent!(attempt, result)
      status = result.provider_status == "delivered" ? "delivered" : "sent"
      now = Time.current
      timestamp = status == "delivered" ? { sent_at: now, delivered_at: now } : { sent_at: now }
      transition!(attempt, status, result, timestamp.merge(provider_message_id: result.provider_message_id))
    end

    def mark_failed!(attempt, result)
      transition!(attempt, "failed", result, failed_at: Time.current, failure_code: result.error_code,
                                              failure_reason: result.error_message)
    end

    def transition!(attempt, status, result, attributes)
      Notification.transaction do
        previous = @notification.status
        @notification.update!(attributes.merge(status:, provider_response: result.response,
                                                http_status: result.http_status,
                                                provider_status: result.provider_status))
        attempt.update!(status:, http_status: result.http_status, provider_status: result.provider_status,
                        provider_message_id: result.provider_message_id, provider_response: result.response,
                        error_code: result.error_code, error_message: result.error_message,
                        completed_at: Time.current)
        event!(status, previous, status, metadata: { "provider_message_id" => result.provider_message_id,
                                                    "failure_code" => result.error_code }.compact)
      end
    end

    def provider
      @notification.whatsapp? ? WhatsAppProvider.new : EmailProvider.new
    end

    def resolve_address
      resolved = RecipientResolver.new(user: @notification.recipient_user, channel: @notification.channel,
                                       primary_guardian: @notification.recipient_guardian.present?,
                                       guardian: @notification.recipient_guardian).call
      resolved.provider_address if resolved.valid?
    end

    def provider_name = @notification.whatsapp? ? "meta_whatsapp" : "resend"
    def request_fingerprint(address) = Digest::SHA256.hexdigest("#{address}:#{@delivery_body || @notification.message_snapshot}")

    def mask(address)
      return "#{address.first}***@#{address.split('@', 2).last}" if @notification.email?

      "+#{'*' * [address.length - 4, 0].max}#{address.last(4)}"
    end

    def event!(type, before_status, after_status, metadata: {})
      @notification.events.create!(actor: @actor, event_type: type,
                                   before_data: { "status" => before_status },
                                   after_data: { "status" => after_status }, metadata:)
    end

    def invalid(key)
      @notification.errors.add(:base, key)
      @notification
    end
  end
end
