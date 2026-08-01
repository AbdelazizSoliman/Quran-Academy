module LessonAttendances
  class RecordDeparture < Mutation
    def initialize(actor:, attendance:, occurred_at: nil)
      super(actor:, attendance:)
      @occurred_at = occurred_at || Time.current
    end

    def call!
      unless @attendance.status.in?(%w[present late left_early]) && @attendance.arrival_at?
        @attendance.errors.add(:departure_at, :invalid_status)
        raise ActiveRecord::RecordInvalid, @attendance
      end
      threshold = AcademySetting.current.left_early_threshold_minutes.minutes
      left_early = @occurred_at < @lesson.ends_at - threshold
      save_with_event!({ departure_at: @occurred_at, status: left_early ? "left_early" : @attendance.status,
                         recorded_at: Time.current, recorded_by: @actor },
                       left_early ? "marked_left_early" : "departure_recorded")
    end
  end
end
