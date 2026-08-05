module Notifications
  class AccountSetupDelivery
    def initialize(invitation:, actor:, token:)
      @invitation = invitation
      @actor = actor
      @token = token
    end

    def call
      return unless deliverable?

      recipient = resolved_recipient
      return unless recipient.valid?

      deliver_to(recipient)
    rescue StandardError => e
      Rails.logger.error("WhatsApp account setup delivery skipped (#{e.class})")
      nil
    end

    private

    def deliver_to(recipient)
      suffix = url_suffix(recipient.locale)
      return if suffix.blank?

      key = idempotency_key
      existing = Notification.find_by(idempotency_key: key)
      return existing if existing

      create_and_send(recipient:, template: template(suffix), idempotency_key: key)
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

    def enabled?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("WHATSAPP_ENABLED", "false")) &&
        AcademySetting.current.whatsapp_notifications_enabled? &&
        AcademySetting.current.invitation_notifications_enabled?
    end

    def configured?
      required_configuration_present? && approved_template_configuration?
    end

    def required_configuration_present?
      %w[WHATSAPP_ACCESS_TOKEN WHATSAPP_PHONE_NUMBER_ID WHATSAPP_BUSINESS_ACCOUNT_ID
         WHATSAPP_GRAPH_API_VERSION WHATSAPP_ACCOUNT_SETUP_URL_PREFIX].all? do |key|
        ENV.fetch(key, nil).present?
      end
    end

    def approved_template_configuration?
      ENV.fetch("WHATSAPP_ACCOUNT_SETUP_TEMPLATE", nil) == "quran_account_setup" &&
        ENV.fetch("WHATSAPP_ACCOUNT_SETUP_LANGUAGE", nil) == "en_US"
    end

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
