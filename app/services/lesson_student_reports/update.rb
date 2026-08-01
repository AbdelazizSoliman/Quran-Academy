module LessonStudentReports
  class Update
    FIELDS = %w[status reading_material reading_from reading_to reading_quality reading_notes memorization_material
                memorization_from memorization_to memorization_result memorization_notes revision_material
                revision_result revision_notes tajweed_topics tajweed_observations mistakes_summary strengths
                areas_for_improvement engagement_level performance_level homework next_lesson_target
                private_teacher_notes student_visible_notes guardian_visible_notes].freeze

    def initialize(actor:, entry:, attributes:)
      @actor = actor
      @entry = entry
      @attributes = attributes.to_h.slice(*FIELDS, *FIELDS.map(&:to_sym))
    end

    def call
      return invalid(validation_error) if validation_error

      LessonStudentReport.transaction { update_entry! }
      @entry
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      invalid(:stale_record)
    end

    private

    def validation_error
      return :forbidden unless assigned_teacher? || administrator?
      return :forbidden if assigned_teacher? && @attributes.with_indifferent_access[:status] == "withheld"

      :report_locked unless @entry.lesson_report.teacher_editable?
    end

    def update_entry!
      @entry.assign_attributes(@attributes)
      changes = @entry.changes.slice(*FIELDS)
      return if changes.empty?

      @entry.updated_by = @actor
      @entry.save!
      create_event!(changes)
    end

    def create_event!(changes)
      safe_changes = changes.except("private_teacher_notes")
      type = changes["status"]&.last == "completed" ? "completed" : "updated"
      LessonStudentReportEvent.create!(lesson_student_report: @entry, actor: @actor, event_type: type,
                                       before_data: safe_changes.transform_values(&:first),
                                       after_data: safe_changes.transform_values(&:last),
                                       metadata: audit_metadata(changes))
    end

    def audit_metadata(changes) = changes.key?("private_teacher_notes") ? { "private_notes_changed" => true } : {}

    def assigned_teacher?
      @actor.active? && @actor.teacher? && @entry.lesson_report.teacher_profile.user_id == @actor.id
    end

    def administrator? = @actor.active? && @actor.admin?

    def invalid(error)
      @entry.errors.add(:base, error)
      @entry
    end
  end
end
