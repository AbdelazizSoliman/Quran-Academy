module LessonAttendances
  class AuditLock
    def initialize(actor:, lesson:)
      @actor = actor
      @lesson = lesson
    end

    def call!
      @lesson.lesson_attendances.find_each do |attendance|
        LessonAttendanceEvent.create!(lesson_attendance: attendance, actor: @actor, event_type: "locked",
                                      after_data: { "attendance_status" => "locked" })
      end
    end
  end
end
