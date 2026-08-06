module Notifications
  # The single authoritative source for which channels an account invitation should be
  # attempted on. Reads the recipient's own stored preference (TeacherProfile#notification_method,
  # StudentProfile#account_delivery_method) rather than any academy-wide delivery toggle, so a
  # recipient who asked for "whatsapp" or "both" actually gets WhatsApp regardless of global mode.
  class InvitationChannels
    DEFAULT = %w[email].freeze
    BY_PREFERENCE = { "email" => %w[email], "whatsapp" => %w[whatsapp], "both" => %w[email whatsapp] }.freeze

    def self.call(user:) = new(user:).call

    def initialize(user:)
      @user = user
    end

    def call
      BY_PREFERENCE.fetch(preference, DEFAULT)
    end

    private

    # Missing/unsupported preference (no profile, or a profile type without this concept)
    # preserves the safe default: email only.
    def preference
      profile = @user.teacher_profile || @user.student_profile
      return profile.notification_method if profile.respond_to?(:notification_method)
      return profile.account_delivery_method if profile.respond_to?(:account_delivery_method)

      nil
    end
  end
end
