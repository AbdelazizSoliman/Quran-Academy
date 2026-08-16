module Notifications
  class AccountSetupDelivery
    def initialize(invitation:, actor:, token:)
      @invitation = invitation
      @actor = actor
      @token = token
    end

    def call
      Rails.logger.info("AccountSetupDelivery started invitation_id=#{@invitation.public_id}")
      recipient = eligible_recipient
      recipient && deliver_to(recipient)
    rescue StandardError => e
      Rails.logger.error(
        "AccountSetupDelivery skipped invitation_id=#{@invitation.public_id} " \
        "exception=#{e.class} message=#{redact(e.message)}"
      )
      nil
    end

    private

    # An exception raised anywhere in this flow could, in principle, embed the raw invitation
    # token or the WhatsApp access token in its message (e.g. a URI-building or HTTP-library
    # error quoting its input) — both are stripped defensively before ever reaching the logs.
    def redact(message)
      return message if message.blank?

      [@token, ENV.fetch("WHATSAPP_ACCESS_TOKEN", nil)].compact.reduce(message) do |redacted, secret|
        secret.present? ? redacted.gsub(secret, "[redacted]") : redacted
      end
    end

    def eligible_recipient
      unless deliverable?
        log_skip(reason: deliverable_skip_reason)
        return
      end

      recipient = resolved_recipient
      return recipient if recipient.valid?

      log_skip(reason: "invalid_recipient:#{recipient.error}", recipient_masked: recipient.masked_address)
      nil
    end

    def deliver_to(recipient)
      suffix = url_suffix(recipient.locale)
      unless suffix
        log_skip(reason: "url_suffix_unavailable", recipient_masked: recipient.masked_address)
        return
      end

      notification = find_or_create_notification(recipient, suffix)
      log_result(notification, recipient)
      mark_invitation_sent(notification)
      notification
    end

    def find_or_create_notification(recipient, suffix)
      key = idempotency_key
      Notification.find_by(idempotency_key: key) ||
        create_and_send(recipient:, template: template(suffix), idempotency_key: key)
    end

    def log_skip(reason:, recipient_masked: nil)
      Rails.logger.info(
        "AccountSetupDelivery skipped invitation_id=#{@invitation.public_id} reason=#{reason} " \
        "recipient=#{recipient_masked.inspect}"
      )
    end

    def log_result(notification, recipient)
      Rails.logger.info(
        "AccountSetupDelivery result invitation_id=#{@invitation.public_id} " \
        "recipient=#{recipient.masked_address.inspect} status=#{notification.status} " \
        "http_status=#{notification.http_status.inspect} provider_status=#{notification.provider_status.inspect} " \
        "provider_message_id=#{notification.provider_message_id.inspect} " \
        "error_code=#{notification.failure_code.inspect} error_message=#{notification.failure_reason.inspect}"
      )
    end

    def deliverable_skip_reason
      return whatsapp_disabled_reason unless enabled?
      return "not_configured" unless configured?

      "invalid_or_stale_token"
    end

    # "whatsapp_disabled" previously covered three independent gates (one ENV kill switch, two
    # per-academy DB flags) — this pinpoints which one is actually false, without guessing.
    def whatsapp_disabled_reason
      log_enabled_diagnostics
      return "whatsapp_disabled:global_flag" unless global_whatsapp_enabled?
      return "whatsapp_disabled:academy_whatsapp_flag" unless academy_whatsapp_enabled?

      "whatsapp_disabled:academy_invitation_flag"
    end

    # global_whatsapp_enabled = WhatsappConfiguration.enabled? (ENV WHATSAPP_ENABLED); the other
    # two are AcademySetting/db columns, independent of any Render env var.
    def log_enabled_diagnostics
      Rails.logger.info(
        "AccountSetupDelivery enabled-check invitation_id=#{@invitation.public_id} " \
        "env_WHATSAPP_ENABLED=#{ENV.fetch('WHATSAPP_ENABLED', nil).inspect} " \
        "global_whatsapp_enabled=#{global_whatsapp_enabled?} academy_whatsapp=#{academy_whatsapp_enabled?} " \
        "academy_invitation=#{academy_invitation_enabled?}"
      )
    end

    def global_whatsapp_enabled? = WhatsappConfiguration.enabled?
    def academy_whatsapp_enabled? = AcademySetting.current.whatsapp_notifications_enabled?
    def academy_invitation_enabled? = AcademySetting.current.invitation_notifications_enabled?

    # WhatsApp delivery runs after the invitation-creating transaction has committed, so this is
    # the first point at which a real success is known. Idempotent: a second successful attempt
    # (retry, or the email channel finishing
    # first) simply no-ops via AccountInvitations::MarkSent's own guard.
    def mark_invitation_sent(notification)
      return unless notification.sent? || notification.delivered?

      AccountInvitations::MarkSent.call(invitation: @invitation, actor: @actor)
    end

    def deliverable? = enabled? && configured? && current_token?

    def resolved_recipient
      RecipientResolver.new(user: @invitation.user, channel: "whatsapp").call
    end

    def url_suffix(locale)
      url = AccountInvitations::UrlBuilder.call(token: @token, locale:)
      AccountSetupUrlSuffix.call(invitation_url: url)
    end

    def idempotency_key
      digest = AccountInvitations::Token.digest(@token)
      "account-setup-whatsapp:#{@invitation.id}:#{digest}"
    end

    def template(suffix)
      AccountSetupTemplate.call(display_name:, email: @invitation.user.email, url_suffix: suffix)
    end

    def enabled? = global_whatsapp_enabled? && academy_whatsapp_enabled? && academy_invitation_enabled?

    def configured? = WhatsappConfiguration.configured?

    def current_token?
      @invitation.usable? && ActiveSupport::SecurityUtils.secure_compare(
        @invitation.token_digest, AccountInvitations::Token.digest(@token)
      )
    end

    def display_name
      @invitation.user.full_name.to_s.strip.presence ||
        @invitation.user.email.to_s.split("@", 2).first.presence || "Account holder"
    end

    def create_and_send(recipient:, template:, idempotency_key:)
      notification = build_notification(recipient, idempotency_key)
      Notification.transaction do
        notification.save!
        create_event(notification)
      end
      attempt(notification, recipient, template)
    rescue ActiveRecord::RecordNotUnique
      Notification.find_by(idempotency_key:)
    end

    def build_notification(recipient, idempotency_key)
      Notification.new(recipient_user: @invitation.user, actor: @actor, source: @invitation,
                       channel: "whatsapp", notification_type: "account_invitation", provider: "meta_whatsapp",
                       recipient_guardian: recipient.guardian, guardian_is_fallback: recipient.guardian.present?,
                       recipient_address_masked: recipient.masked_address, recipient_locale: recipient.locale,
                       subject: nil, message_snapshot: I18n.t("notifications.secure_link_omitted"), idempotency_key:)
    end

    def create_event(notification)
      notification.events.create!(actor: @actor, event_type: "created", after_data: { "status" => "pending" })
    end

    def attempt(notification, recipient, template)
      Attempt.new(notification:, actor: @actor, recipient_address: recipient.provider_address,
                  delivery_body: "account setup template", provider_options: { template: }).call
    end
  end
end
