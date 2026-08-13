module Notifications
  class LateAttendanceReminderScheduler
    MINUTES_AFTER = 5
    CATCH_UP_WINDOW = 1.day

    def initialize(actor:, now: Time.current, relation: ScheduledLesson.all)
      @actor = actor
      @now = now
      @relation = relation
      @setting = AcademySetting.current
    end

    def call
      return [] unless enabled?

      due_lessons.flat_map { |lesson| notify_due_stages(lesson) }
    end

    private

    def enabled?
      @setting.lesson_reminders_enabled? && @setting.whatsapp_notifications_enabled? &&
        WhatsappConfiguration.lesson_reminders_ready?
    end

    def due_lessons
      lower_bound = @now - CATCH_UP_WINDOW
      upper_bound = @now - MINUTES_AFTER.minutes
      @relation.where(status: %w[scheduled in_progress])
               .where(starts_at: lower_bound..upper_bound)
               .includes(teacher_profile: :user,
                         scheduled_lesson_enrollments: [
                           :lesson_attendance, { student_profile: :user }, { enrollment: { student_profile: :user } }
                         ])
    end

    def notify_due_stages(lesson)
      recipients = []
      recipients << lesson.teacher_profile.user unless teacher_joined?(lesson)
      recipients.concat(absent_students(lesson))
      recipients.uniq(&:id).filter_map { |recipient| notify_recipient(lesson, recipient) }
    end

    def teacher_joined?(lesson)
      joined = lesson.teacher_checked_in_at.present?
      Rails.logger.info("LessonReminder skipped reason=already_joined") if joined
      joined
    end

    def absent_students(lesson)
      lesson.scheduled_lesson_enrollments.filter_map do |participation|
        next unless participation.expected?

        attendance = participation.lesson_attendance
        joined = attendance&.arrival_at.present? || attendance&.status.in?(%w[present late left_early])
        if joined
          Rails.logger.info("LessonReminder skipped reason=already_joined")
          next
        end
        participation.student_profile&.user
      end
    end

    def notify_recipient(lesson, recipient)
      return unless LessonReminderRecipient.whatsapp_selected?(recipient)

      Rails.logger.info("LessonReminder whatsapp dispatch started lesson_id=#{lesson.id}")
      notification = Dispatch.new(actor: @actor, recipient:, source: lesson, type: "lesson_late_reminder",
                                  channel: "whatsapp", scheduled_at: lesson.starts_at + MINUTES_AFTER.minutes,
                                  queued_at: @now, idempotency_key: idempotency_key(lesson, recipient)).call
      log_finished(notification)
      notification
    end

    def idempotency_key(lesson, recipient)
      "lesson-late-reminder:lesson:#{lesson.id}:recipient:#{recipient.id}"
    end

    def log_finished(notification)
      Rails.logger.info("LessonReminder whatsapp dispatch finished " \
                        "success=#{notification.sent? || notification.delivered?}")
    end
  end
end
