module LessonAttendances
  class MarkPresent < Mutation
    def call!
      save_with_event!({ status: "present", minutes_late: 0, recorded_at: Time.current, recorded_by: @actor },
                       "marked_present")
    end
  end
end
