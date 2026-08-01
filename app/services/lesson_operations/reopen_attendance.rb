module LessonOperations
  class ReopenAttendance < Base
    def initialize(actor:, lesson:, reason:)
      super(actor:, lesson:)
      @reason = reason
    end

    def call
      return failed(:forbidden) unless administrator?
      return failed(:reopen_reason_required) if @reason.blank?
      return failed(:invalid_attendance_status) unless @lesson.attendance_locked?

      ScheduledLesson.transaction { reopen! }
      @lesson
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      failed(:stale_record)
    end

    private

    def reopen!
      @lesson.update!(attendance_status: "reopened", attendance_reopened_at: Time.current,
                      attendance_reopened_by: @actor, updated_by: @actor)
      event!(:attendance_reopened, before_data: { "attendance_status" => "locked" },
                                   after_data: { "attendance_status" => "reopened" },
                                   metadata: { "reason" => @reason })
      LessonAttendances::AuditReopen.new(actor: @actor, lesson: @lesson, reason: @reason).call!
    end
  end
end
