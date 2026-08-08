module Notifications
  # Shared, side-effect-free check for whether the WhatsApp Cloud API is technically usable
  # right now: the env-level kill switch, required credentials, and approved templates.
  # Account setup and lesson reminders intentionally have separate readiness checks because
  # each template has its own fixed URL prefix and approval lifecycle.
  class WhatsappConfiguration
    PROVIDER_KEYS = %w[WHATSAPP_ACCESS_TOKEN WHATSAPP_PHONE_NUMBER_ID WHATSAPP_BUSINESS_ACCOUNT_ID
                       WHATSAPP_GRAPH_API_VERSION].freeze
    ACCOUNT_SETUP_KEYS = %w[WHATSAPP_ACCOUNT_SETUP_URL_PREFIX].freeze
    LESSON_REMINDER_KEYS = %w[WHATSAPP_LESSON_JOIN_URL_PREFIX].freeze
    APPROVED_TEMPLATE = "quran_account_setup".freeze
    APPROVED_LANGUAGE = "en_US".freeze

    def self.enabled? = ActiveModel::Type::Boolean.new.cast(ENV.fetch("WHATSAPP_ENABLED", "false"))

    def self.configured?
      keys_present?(PROVIDER_KEYS + ACCOUNT_SETUP_KEYS) && approved_template?
    end

    def self.approved_template?
      ENV.fetch("WHATSAPP_ACCOUNT_SETUP_TEMPLATE", nil) == APPROVED_TEMPLATE &&
        ENV.fetch("WHATSAPP_ACCOUNT_SETUP_LANGUAGE", nil) == APPROVED_LANGUAGE
    end

    def self.ready? = enabled? && configured?

    def self.lesson_reminders_configured?
      keys_present?(PROVIDER_KEYS + LESSON_REMINDER_KEYS) &&
        ENV.fetch("WHATSAPP_LESSON_REMINDER_TEMPLATE", nil) == "quran_lesson_reminder" &&
        ENV.fetch("WHATSAPP_LESSON_REMINDER_LANGUAGE", nil) == "en_US"
    end

    def self.lesson_reminders_ready? = enabled? && lesson_reminders_configured?

    def self.keys_present?(keys) = keys.all? { |key| ENV.fetch(key, nil).present? }
    private_class_method :keys_present?
  end
end
