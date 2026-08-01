module LessonOperations
  class CheckIn < Base
    def initialize(actor:, lesson:, override: false, reason: nil, occurred_at: nil)
      super(actor:, lesson:)
      @override = override
      @reason = reason
      @occurred_at = occurred_at || Time.current
    end

    def call
      error = precondition_error
      return error if error

      ScheduledLesson.transaction { check_in! }
      @lesson
    rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordInvalid
      failed(:stale_record)
    end

    private

    def precondition_error
      return @lesson if @lesson.teacher_checked_in_at?
      return failed(:invalid_status) unless @lesson.scheduled? || @lesson.in_progress?

      error = authorization_error
      return error if error

      failed(:outside_check_in_window) unless @override || within_window?
    end

    def authorization_error
      return failed(:override_reason_required) if invalid_override?

      failed(:forbidden) unless authorized?
    end

    def check_in!
      @lesson.lock!
      return if @lesson.teacher_checked_in_at?

      status = teacher_status
      @lesson.update!(teacher_checked_in_at: @occurred_at, teacher_attendance_status: status, updated_by: @actor)
      event!(:teacher_checked_in, after_data: { "teacher_checked_in_at" => @occurred_at,
                                                "teacher_attendance_status" => status },
                                  metadata: { "mode" => mode, "reason" => @reason }.compact)
    end

    def invalid_override? = @override && (!administrator? || @reason.blank?)
    def authorized? = @override ? administrator? : assigned_teacher?

    def within_window?
      settings = AcademySetting.current
      window = ((@lesson.starts_at - settings.teacher_check_in_opens_minutes_before.minutes)..
                (@lesson.starts_at + settings.teacher_check_in_closes_minutes_after.minutes))
      window.cover?(@occurred_at)
    end

    def teacher_status
      return "administrator_override" if @override

      threshold = AcademySetting.current.teacher_late_after_minutes.minutes
      @occurred_at > @lesson.starts_at + threshold ? "late" : "on_time"
    end

    def mode = @override ? "administrator_override" : "teacher_self"
  end
end
