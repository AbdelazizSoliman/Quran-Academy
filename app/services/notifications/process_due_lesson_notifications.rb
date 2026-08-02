module Notifications
  class ProcessDueLessonNotifications
    def initialize(actor:, now: Time.current)
      @actor = actor
      @now = now
    end

    def call
      {
        lesson_reminders: LessonReminderScheduler.new(actor: @actor, now: @now).call,
        late_attendance_reminders: LateAttendanceReminderScheduler.new(actor: @actor, now: @now).call
      }
    end
  end
end
