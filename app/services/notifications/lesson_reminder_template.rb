module Notifications
  class LessonReminderTemplate
    CONTEXTS = {
      "lesson_pre_reminder" => "Your lesson starts in 15 minutes.",
      "lesson_late_reminder" => "Your lesson started 5 minutes ago. Please join now."
    }.freeze

    def self.call(notification:, url_suffix:)
      lesson = notification.source
      local_start = lesson.starts_at.in_time_zone(lesson.academy_time_zone)
      values = body_values(notification, lesson, local_start)
      body = { type: "body", parameters: values.map { |value| { type: "text", text: value.to_s } } }
      button = { type: "button", sub_type: "url", index: "0",
                 parameters: [{ type: "text", text: url_suffix }] }
      { name: ENV.fetch("WHATSAPP_LESSON_REMINDER_TEMPLATE", "quran_lesson_reminder"),
        language_code: ENV.fetch("WHATSAPP_LESSON_REMINDER_LANGUAGE", "en_US"), components: [body, button] }
    end

    def self.body_values(notification, lesson, local_start)
      label, counterpart_name = counterpart(notification, lesson)
      [notification.recipient_user.full_name, localized_date(notification, local_start),
       local_start.strftime("%H:%M"), label, counterpart_name, CONTEXTS.fetch(notification.notification_type)]
    end

    def self.counterpart(notification, lesson)
      locale = notification.recipient_locale
      unless notification.recipient_user.teacher?
        return [I18n.t("notifications.messages.counterpart_teacher", locale:),
                lesson.teacher_profile.display_name]
      end

      students = student_names(lesson)
      name = students.one? ? students.first : I18n.t("notifications.messages.students", locale:)
      [I18n.t("notifications.messages.counterpart_student", locale:), name]
    end

    def self.student_names(lesson)
      lesson.scheduled_lesson_enrollments.expected.includes(enrollment: :student_profile)
            .map { |item| item.enrollment.student_profile.display_name }
    end

    def self.localized_date(notification, local_start)
      I18n.with_locale(notification.recipient_locale) { I18n.l(local_start.to_date, format: :long) }
    end

    private_class_method :body_values, :counterpart, :student_names, :localized_date
  end
end
