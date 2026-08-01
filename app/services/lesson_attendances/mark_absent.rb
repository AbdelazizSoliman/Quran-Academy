module LessonAttendances
  class MarkAbsent < Mutation
    def initialize(actor:, attendance:, override: false, reason: nil, completion_confirmation: false)
      super(actor:, attendance:)
      @override = ActiveModel::Type::Boolean.new.cast(override)
      @reason = reason
      @completion_confirmation = completion_confirmation
    end

    def call!
      early = Time.current < @lesson.starts_at + AcademySetting.current.absence_after_minutes.minutes
      if early && !permitted_early_absence?
        @attendance.errors.add(:base, :absence_threshold_not_reached)
        raise ActiveRecord::RecordInvalid, @attendance
      end
      save_with_event!({ status: "absent", recorded_at: Time.current, recorded_by: @actor }, "marked_absent",
                       metadata: { "override_reason" => @reason }.compact)
    end

    private

    def permitted_early_absence?
      @completion_confirmation || (administrator? && @override && @reason.present?)
    end
  end
end
