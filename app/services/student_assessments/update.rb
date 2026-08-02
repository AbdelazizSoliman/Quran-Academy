module StudentAssessments
  class Update
    SAFE_FIELDS = %w[assessment_date scheduled_lesson_id notes lock_version].freeze

    def initialize(actor:, assessment:, attributes:, scores: {})
      @actor = actor
      @assessment = assessment
      @attributes = attributes.slice(*SAFE_FIELDS)
      @scores = scores
    end

    def call
      return invalid(:forbidden) unless authorized?
      return invalid(:not_editable) unless @assessment.editable?

      StudentAssessment.transaction do
        before = audit_snapshot
        @assessment.update!(@attributes.merge(updated_by: @actor))
        update_scores!
        recalculate!
        after = audit_snapshot
        create_event(before, after) if before != after
      end
      @assessment
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      invalid(:invalid_update)
    end

    private

    def authorized?
      @actor.active? && (@actor.admin? || (@actor.teacher? && @assessment.teacher_profile.user_id == @actor.id))
    end

    def update_scores!
      @scores.each do |id, values|
        score = @assessment.scores.find(id)
        score.update!(values.slice("numeric_score", "rating", "comments", "lock_version"))
      end
    end

    def recalculate!
      result = Assessments::GradeCalculator.new(scores: @assessment.scores.includes(:assessment_rubric_item)).call
      @assessment.update!(overall_score: result[:percentage], letter_grade: result[:letter_grade])
    end

    def audit_snapshot
      @assessment.reload
      values = @assessment.attributes.slice("assessment_date", "overall_score", "letter_grade")
      values["notes_digest"] = Digest::SHA256.hexdigest(@assessment.notes.to_s)
      values["scores"] = @assessment.scores.order(:assessment_rubric_item_id).map do |score|
        score.attributes.slice("assessment_rubric_item_id", "numeric_score", "rating")
      end
      values
    end

    def create_event(before, after)
      changed = (before.keys | after.keys).select { |key| before[key] != after[key] }
      @assessment.events.create!(actor: @actor, event_type: "updated",
                                 before_data: before.slice(*changed), after_data: after.slice(*changed))
    end

    def invalid(key)
      @assessment.errors.add(:base, key)
      @assessment
    end
  end
end
