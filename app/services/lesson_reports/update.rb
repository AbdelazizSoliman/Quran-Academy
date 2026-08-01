module LessonReports
  class Update
    FIELDS = %w[lesson_summary topics_covered general_teacher_notes general_homework next_lesson_plan
                overall_engagement overall_progress report_language].freeze

    def initialize(actor:, report:, attributes:)
      @actor = actor
      @report = report
      @attributes = attributes.to_h.slice(*FIELDS, *FIELDS.map(&:to_sym))
    end

    def call
      return invalid(validation_error) if validation_error

      LessonReport.transaction { update_report! }
      @report
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      invalid(:stale_record)
    end

    private

    def validation_error
      return :forbidden unless assigned_teacher? || administrator?

      :report_locked unless @report.teacher_editable?
    end

    def update_report!
      @report.assign_attributes(@attributes)
      changes = @report.changes.slice(*FIELDS)
      return if changes.empty?

      @report.updated_by = @actor
      @report.save!
      LessonReportEvent.create!(lesson_report: @report, actor: @actor, event_type: "updated",
                                before_data: changes.transform_values(&:first),
                                after_data: changes.transform_values(&:last))
    end

    def assigned_teacher?
      @actor.active? && @actor.teacher? && @report.teacher_profile.user_id == @actor.id
    end

    def administrator? = @actor.active? && @actor.admin?

    def invalid(error)
      @report.errors.add(:base, error)
      @report
    end
  end
end
