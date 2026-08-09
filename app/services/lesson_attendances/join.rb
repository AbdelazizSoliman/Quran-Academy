module LessonAttendances
  class Join
    def initialize(actor:, lesson:, participation:, occurred_at: Time.current)
      @actor = actor
      @lesson = lesson
      @participation = participation
      @occurred_at = occurred_at
    end

    def call
      LessonAttendance.transaction do
        attendance = attendance_for_participant
        if attendance.arrival_at?
          attendance
        else
          RecordArrival.new(actor: @actor, attendance:, occurred_at: @occurred_at, allow_scheduled: true).call
        end
      end
    end

    private

    def attendance_for_participant
      @participation.lesson_attendance || create_attendance
    end

    def create_attendance
      attendance = @lesson.lesson_attendances.create_or_find_by!(scheduled_lesson_enrollment: @participation)
      if attendance.previously_new_record?
        attendance.events.create!(actor: @actor, event_type: "initialized", after_data: { "status" => "pending" })
      end
      attendance
    end
  end
end
