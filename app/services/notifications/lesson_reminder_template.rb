module Notifications
  class LessonReminderTemplate
    CONTEXTS = {
      "lesson_pre_reminder" => "Your lesson starts in 15 minutes.",
      "lesson_late_reminder" => "Your lesson started 5 minutes ago. Please join now."
    }.freeze

    def self.call(notification:, url_suffix:)
      lesson = notification.source
      local_start = EffectiveTimeZone.local_time(lesson.starts_at, user: notification.recipient_user)
      values = body_values(notification, lesson, local_start)
      body = { type: "body", parameters: values.map { |value| { type: "text", text: value.to_s } } }
      button = { type: "button", sub_type: "url", index: "0",
                 parameters: [{ type: "text", text: url_suffix }] }
      { name: ENV.fetch("WHATSAPP_LESSON_REMINDER_TEMPLATE", "quran_lesson_reminder"),
        language_code: ENV.fetch("WHATSAPP_LESSON_REMINDER_LANGUAGE"), components: [body, button] }
    end

    def self.body_values(notification, lesson, local_start)
      [localized_date_and_time(notification, local_start), counterpart(notification, lesson),
       CONTEXTS.fetch(notification.notification_type)]
    end

    def self.counterpart(notification, lesson)
      locale = notification.recipient_locale
      return lesson.teacher_profile.display_name unless notification.recipient_user.teacher?

      students = student_names(lesson)
      students.one? ? students.first : I18n.t("notifications.messages.students", locale:)
    end

    def self.student_names(lesson)
      lesson.scheduled_lesson_enrollments.expected.includes(:student_profile, enrollment: :student_profile)
            .filter_map { |item| item.student_profile&.display_name }
    end

    def self.localized_date_and_time(notification, local_start)
      I18n.with_locale(notification.recipient_locale) do
        "#{I18n.l(local_start.to_date, format: :long)} #{I18n.l(local_start, format: :time)}"
      end
    end

    private_class_method :body_values, :counterpart, :student_names, :localized_date_and_time
  end
end
