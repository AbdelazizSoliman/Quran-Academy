module Notifications
  class LessonJoinUrlBuilder
    def self.call(lesson:, recipient:)
      helpers = Rails.application.routes.url_helpers
      options = Rails.application.config.action_mailer.default_url_options
      return helpers.join_teacher_schedule_url(lesson, **options) if recipient.teacher?

      helpers.join_student_schedule_url(lesson, **options) if recipient.student?
    end
  end
end
