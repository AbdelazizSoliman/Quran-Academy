module LessonOperations
  class Complete < Base
    def initialize(actor:, lesson:, options: {})
      super(actor:, lesson:)
      @mark_unresolved_absent = ActiveModel::Type::Boolean.new.cast(options[:mark_unresolved_absent])
      @override = options[:override]
      @reason = options[:reason]
      @notes = options[:notes]
    end

    def call
      error = precondition_error
      return error if error

      ScheduledLesson.transaction do
        @lesson.lock!
        finalize_unresolved!
        complete_lesson!
      end
      @lesson
    rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordInvalid
      failed(:stale_record)
    end

    private

    def precondition_error
      return @lesson if @lesson.completed?
      return failed(:invalid_status) unless @lesson.in_progress?

      error = authorization_error
      return error if error

      failed(:unresolved_attendance) if unresolved? && !can_finalize_unresolved?
    end

    def authorization_error
      return failed(:forbidden) unless @override ? administrator? : assigned_teacher?

      failed(:override_reason_required) if @override && @reason.blank?
    end

    def unresolved? = @lesson.lesson_attendances.unresolved.exists?
    def can_finalize_unresolved? = @mark_unresolved_absent || @override

    def finalize_unresolved!
      @lesson.lesson_attendances.unresolved.find_each do |attendance|
        LessonAttendances::MarkAbsent.new(actor: @actor, attendance:, override: true,
                                          reason: @reason.presence || "completion_confirmation",
                                          completion_confirmation: true).call!
      end
    end

    def complete_lesson!
      now = Time.current
      @lesson.update!(status: "completed", ended_at: now, completed_at: now, completion_notes: @notes,
                      attendance_status: "locked", attendance_locked_at: now,
                      attendance_locked_by: @actor, updated_by: @actor)
      event!(:completed, before_data: { "status" => "in_progress" },
                         after_data: { "status" => "completed", "ended_at" => now })
      event!(:attendance_locked, after_data: { "attendance_status" => "locked" })
      LessonAttendances::AuditLock.new(actor: @actor, lesson: @lesson).call!
    end
  end
end
