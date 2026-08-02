module Notifications
  class LateAttendanceReminderScheduler
    STAGES = { "first" => :first_late_reminder_minutes,
               "second" => :second_late_reminder_minutes }.freeze

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
      @setting.lesson_reminders_enabled? && @setting.whatsapp_notifications_enabled?
    end

    def due_lessons
      earliest = @now - 1.day
      @relation.where(status: %w[scheduled in_progress], starts_at: earliest..@now)
               .includes(teacher_profile: :user,
                         scheduled_lesson_enrollments: [
                           :lesson_attendance, { enrollment: { student_profile: :user } }
                         ])
    end

    def notify_due_stages(lesson)
      pending = pending_participants(lesson)
      return [] if pending.empty?

      STAGES.flat_map do |stage, setting_attribute|
        minutes = @setting.public_send(setting_attribute)
        next [] if @now < lesson.starts_at + minutes.minutes

        notify_stage(lesson, pending, stage, minutes)
      end
    end

    def pending_participants(lesson)
      lesson.scheduled_lesson_enrollments.select do |participation|
        participation.expected? && (participation.lesson_attendance.nil? || participation.lesson_attendance.pending?)
      end
    end

    def notify_stage(lesson, pending, stage, minutes)
      recipients = [lesson.teacher_profile.user, *pending.map { |item| item.enrollment.student_profile.user }]
      recipients.uniq(&:id).map do |recipient|
        Dispatch.new(actor: @actor, recipient:, source: lesson, type: "late_reminder", channel: "whatsapp",
                     scheduled_at: lesson.starts_at + minutes.minutes, queued_at: @now,
                     idempotency_key: idempotency_key(lesson, recipient, stage)).call
      end
    end

    def idempotency_key(lesson, recipient, stage)
      "late-reminder:#{stage}:lesson:#{lesson.id}:recipient:#{recipient.id}"
    end
  end
end
