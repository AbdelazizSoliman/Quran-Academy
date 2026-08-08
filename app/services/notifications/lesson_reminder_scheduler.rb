module Notifications
  class LessonReminderScheduler
    MINUTES_BEFORE = 15
    SWEEP_WINDOW = 1.minute

    def initialize(actor:, now: Time.current, relation: ScheduledLesson.all)
      @actor = actor
      @now = now
      @relation = relation
      @setting = AcademySetting.current
    end

    def call
      return [] unless enabled?

      due_lessons.flat_map { |lesson| notify_lesson(lesson) }
    end

    private

    def enabled?
      @setting.lesson_reminders_enabled? && @setting.whatsapp_notifications_enabled? &&
        WhatsappConfiguration.lesson_reminders_ready?
    end

    def due_lessons
      lower_bound = @now + MINUTES_BEFORE.minutes - SWEEP_WINDOW
      upper_bound = @now + MINUTES_BEFORE.minutes
      @relation.where(status: "scheduled").where("starts_at > ? AND starts_at <= ?", lower_bound, upper_bound)
               .includes(teacher_profile: :user,
                         scheduled_lesson_enrollments: { enrollment: { student_profile: :user } })
    end

    def notify_lesson(lesson)
      scheduled_at = lesson.starts_at - MINUTES_BEFORE.minutes
      recipients(lesson).filter_map do |recipient|
        next unless LessonReminderRecipient.whatsapp_selected?(recipient)

        dispatch(lesson, recipient, scheduled_at)
      end
    end

    def dispatch(lesson, recipient, scheduled_at)
      Rails.logger.info("LessonReminder whatsapp dispatch started lesson_id=#{lesson.id}")
      notification = Dispatch.new(actor: @actor, recipient:, source: lesson, type: "lesson_pre_reminder",
                                  channel: "whatsapp", scheduled_at:, queued_at: @now,
                                  idempotency_key: idempotency_key(lesson, recipient)).call
      log_finished(notification)
      notification
    end

    def recipients(lesson)
      students = lesson.scheduled_lesson_enrollments.select(&:expected?).map do |participation|
        participation.enrollment.student_profile.user
      end
      [lesson.teacher_profile.user, *students].uniq(&:id)
    end

    def idempotency_key(lesson, recipient)
      "lesson-pre-reminder:lesson:#{lesson.id}:recipient:#{recipient.id}"
    end

    def log_finished(notification)
      Rails.logger.info("LessonReminder whatsapp dispatch finished " \
                        "success=#{notification.sent? || notification.delivered?}")
    end
  end
end
