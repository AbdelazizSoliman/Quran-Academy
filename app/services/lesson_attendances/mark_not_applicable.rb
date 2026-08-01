module LessonAttendances
  class MarkNotApplicable < Mutation
    def call!
      save_with_event!({ status: "not_applicable", recorded_at: Time.current, recorded_by: @actor },
                       "marked_not_applicable")
    end
  end
end
