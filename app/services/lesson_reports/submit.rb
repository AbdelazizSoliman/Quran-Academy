module LessonReports
  class Submit
    def initialize(actor:, report:)
      @actor = actor
      @report = report
    end

    def call
      return @report if @report.submitted?
      return invalid(submission_error) if submission_error

      LessonReport.transaction { submit! }
      @report
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      invalid(:stale_record)
    end

    private

    def submission_error
      return :forbidden unless assigned_teacher?
      return :lesson_not_completed unless @report.scheduled_lesson.completed?
      return :attendance_not_locked unless @report.scheduled_lesson.attendance_locked?
      return :summary_required if @report.lesson_summary.blank?
      return :unresolved_entries if @report.unresolved_entries?

      :invalid_status unless @report.teacher_editable?
    end

    def submit!
      now = Time.current
      previous = @report.status
      @report.update!(status: "submitted", submitted_at: now, submitted_by: @actor, updated_by: @actor)
      LessonReportEvent.create!(lesson_report: @report, actor: @actor, event_type: "submitted",
                                before_data: { "status" => previous },
                                after_data: { "status" => "submitted", "submitted_at" => now })
    end

    def assigned_teacher?
      @actor.active? && @actor.teacher? && @report.teacher_profile.user_id == @actor.id
    end

    def invalid(error)
      @report.errors.add(:base, error)
      @report
    end
  end
end
