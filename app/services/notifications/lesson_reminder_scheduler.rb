module Notifications
  class LessonReminderScheduler
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
      @setting.lesson_reminders_enabled? && @setting.whatsapp_notifications_enabled?
    end

    def due_lessons
      upper_bound = @now + @setting.lesson_reminder_minutes_before.minutes
      @relation.where(status: "scheduled", starts_at: @now..upper_bound)
               .includes(teacher_profile: :user,
                         scheduled_lesson_enrollments: { enrollment: { student_profile: :user } })
    end

    def notify_lesson(lesson)
      scheduled_at = lesson.starts_at - @setting.lesson_reminder_minutes_before.minutes
      recipients(lesson).map do |recipient|
        Dispatch.new(actor: @actor, recipient:, source: lesson, type: "lesson_reminder", channel: "whatsapp",
                     scheduled_at:, queued_at: @now,
                     idempotency_key: idempotency_key(lesson, recipient)).call
      end
    end

    def recipients(lesson)
      students = lesson.scheduled_lesson_enrollments.select(&:expected?).map do |participation|
        participation.enrollment.student_profile.user
      end
      [lesson.teacher_profile.user, *students].uniq(&:id)
    end

    def idempotency_key(lesson, recipient)
      "lesson-reminder:#{lesson.id}:recipient:#{recipient.id}"
    end
  end
end
