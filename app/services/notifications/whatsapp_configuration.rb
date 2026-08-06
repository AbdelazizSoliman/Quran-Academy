module Notifications
  # Shared, side-effect-free check for whether the WhatsApp Cloud API is technically usable
  # right now: the env-level kill switch, required credentials, and the one approved account
  # setup template. Reused by InvitationDelivery (to decide/log a skip before enqueueing) and
  # AccountSetupDelivery (to re-validate, defense-in-depth, at actual send time).
  class WhatsappConfiguration
    REQUIRED_KEYS = %w[WHATSAPP_ACCESS_TOKEN WHATSAPP_PHONE_NUMBER_ID WHATSAPP_BUSINESS_ACCOUNT_ID
                       WHATSAPP_GRAPH_API_VERSION WHATSAPP_ACCOUNT_SETUP_URL_PREFIX].freeze
    APPROVED_TEMPLATE = "quran_account_setup".freeze
    APPROVED_LANGUAGE = "en_US".freeze

    def self.enabled? = ActiveModel::Type::Boolean.new.cast(ENV.fetch("WHATSAPP_ENABLED", "false"))

    def self.configured?
      REQUIRED_KEYS.all? { |key| ENV.fetch(key, nil).present? } && approved_template?
    end

    def self.approved_template?
      ENV.fetch("WHATSAPP_ACCOUNT_SETUP_TEMPLATE", nil) == APPROVED_TEMPLATE &&
        ENV.fetch("WHATSAPP_ACCOUNT_SETUP_LANGUAGE", nil) == APPROVED_LANGUAGE
    end

    def self.ready? = enabled? && configured?
  end
end
