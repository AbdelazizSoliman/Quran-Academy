module LessonAttendances
  class AuditReopen
    def initialize(actor:, lesson:, reason:)
      @actor = actor
      @lesson = lesson
      @reason = reason
    end

    def call!
      @lesson.lesson_attendances.find_each do |attendance|
        LessonAttendanceEvent.create!(lesson_attendance: attendance, actor: @actor, event_type: "reopened",
                                      after_data: { "attendance_status" => "reopened" },
                                      metadata: { "reason" => @reason })
      end
    end
  end
end
