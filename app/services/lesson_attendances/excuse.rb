module LessonAttendances
  class Excuse < Mutation
    def initialize(actor:, attendance:, reason:)
      super(actor:, attendance:)
      @reason = reason
    end

    def call!
      if @reason.blank?
        @attendance.errors.add(:excuse_reason, :blank)
        raise ActiveRecord::RecordInvalid, @attendance
      end
      save_with_event!({ status: "excused_absence", excuse_reason: @reason, recorded_at: Time.current,
                         recorded_by: @actor }, "excused")
    end
  end
end
