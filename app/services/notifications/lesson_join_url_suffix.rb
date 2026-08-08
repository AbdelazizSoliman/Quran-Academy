require "uri"

module Notifications
  class LessonJoinUrlSuffix
    def self.call(join_url:, configured_prefix: ENV.fetch("WHATSAPP_LESSON_JOIN_URL_PREFIX", nil))
      AccountSetupUrlSuffix.call(invitation_url: join_url, configured_prefix:)
    end
  end
end
