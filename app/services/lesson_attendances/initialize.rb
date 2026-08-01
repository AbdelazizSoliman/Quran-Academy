module LessonAttendances
  class Initialize
    def initialize(actor:, lesson:)
      @actor = actor
      @lesson = lesson
    end

    def call
      LessonAttendance.transaction { call! }
      @lesson.lesson_attendances.reload
    end

    def call!
      @lesson.scheduled_lesson_enrollments.where(participation_status: "expected").find_each do |participant|
        attendance = @lesson.lesson_attendances.find_or_initialize_by(scheduled_lesson_enrollment: participant)
        next if attendance.persisted?

        attendance.save!
        LessonAttendanceEvent.create!(lesson_attendance: attendance, actor: @actor, event_type: "initialized",
                                      after_data: { "status" => "pending" })
      end
    end
  end
end
