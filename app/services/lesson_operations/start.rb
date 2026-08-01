module LessonOperations
  class Start < Base
    def initialize(actor:, lesson:, override: false, reason: nil)
      super(actor:, lesson:)
      @override = override
      @reason = reason
    end

    def call
      error = precondition_error
      return error if error

      ScheduledLesson.transaction { start! }
      @lesson
    rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordInvalid
      failed(:stale_record)
    end

    private

    def precondition_error
      return @lesson if @lesson.in_progress?
      return failed(:invalid_status) unless @lesson.scheduled?

      error = authorization_error
      return error if error

      failed(:teacher_check_in_required) unless @lesson.teacher_checked_in_at? || @override
    end

    def authorization_error
      return failed(:forbidden) unless @override ? administrator? : assigned_teacher?

      failed(:override_reason_required) if @override && @reason.blank?
    end

    def start!
      @lesson.lock!
      raise ActiveRecord::StaleObjectError unless @lesson.scheduled?

      now = Time.current
      @lesson.update!(status: "in_progress", started_at: now, attendance_status: "open",
                      attendance_opened_at: now, updated_by: @actor)
      LessonAttendances::Initialize.new(actor: @actor, lesson: @lesson).call!
      event!(:started, before_data: { "status" => "scheduled" },
                       after_data: { "status" => "in_progress", "started_at" => now }, metadata: override_metadata)
      event!(:attendance_opened, after_data: { "attendance_status" => "open" })
    end

    def override_metadata
      @override ? { "mode" => "administrator_override", "reason" => @reason } : {}
    end
  end
end
