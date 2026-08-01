module LessonAttendances
  class RecordArrival < Mutation
    def initialize(actor:, attendance:, occurred_at: nil, adjustment_reason: nil)
      super(actor:, attendance:)
      @occurred_at = occurred_at || Time.current
      @adjustment_reason = adjustment_reason
    end

    def call!
      reject_unadjusted_overwrite!
      attributes = { arrival_at: @occurred_at, minutes_late:, status:, recorded_at: Time.current,
                     recorded_by: @actor }
      if @adjustment_reason.present?
        attributes.merge!(last_adjusted_at: Time.current, last_adjusted_by: @actor,
                          adjustment_reason: @adjustment_reason)
      end
      save_with_event!(attributes, event_type)
    end

    private

    def reject_unadjusted_overwrite!
      return unless @attendance.arrival_at? && @adjustment_reason.blank?

      @attendance.errors.add(:arrival_at, :already_recorded)
      raise ActiveRecord::RecordInvalid, @attendance
    end

    def minutes_late
      [((@occurred_at - @lesson.starts_at) / 60).floor, 0].max
    end

    def status
      minutes_late > AcademySetting.current.student_late_after_minutes ? "late" : "present"
    end

    def event_type = status == "late" ? "marked_late" : "arrival_recorded"
  end
end
