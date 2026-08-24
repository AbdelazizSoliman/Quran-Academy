module StudentAssessments
  class Create
    def initialize(actor:, attributes:, category_scores: {})
      @actor = actor
      @attributes = attributes
      @category_scores = category_scores.to_h.stringify_keys
    end

    def call
      assessment = build_assessment
      return forbidden(assessment) unless authorized?(assessment)
      return assessment unless valid_category_scores?(assessment)

      StudentAssessment.transaction { persist!(assessment) }
      assessment
    rescue ActiveRecord::RecordInvalid
      assessment
    end

    private

    def build_assessment
      StudentAssessment.new(@attributes).tap do |assessment|
        assessment.student_profile ||= assessment.enrollment&.student_profile
        assessment.created_by = assessment.updated_by = @actor
      end
    end

    def persist!(assessment)
      assessment.save!
      initialize_scores!(assessment)
      apply_category_scores!(assessment)
      recalculate!(assessment) if @category_scores.any?
      event!(assessment, "created", after_data: snapshot(assessment))
    end

    def authorized?(assessment)
      return false unless @actor.active?
      return true if @actor.admin?

      @actor.teacher? && assessment.teacher_profile&.user_id == @actor.id && assigned_student?(assessment)
    end

    def assigned_student?(assessment)
      if assessment.scheduled_lesson
        return assessment.scheduled_lesson.teacher_profile_id == assessment.teacher_profile_id &&
               assessment.scheduled_lesson.scheduled_lesson_enrollments.expected
                         .for_student_profile_ids([assessment.student_profile_id]).exists?
      end

      ScheduledLesson.exists?(teacher_profile: assessment.teacher_profile,
                              course_offering_id: assessment.enrollment&.course_offering_id)
    end

    def initialize_scores!(assessment)
      assessment.assessment_template.rubric_items.find_each do |rubric|
        assessment.scores.create!(assessment_rubric_item: rubric)
      end
    end

    def valid_category_scores?(assessment)
      return true if @category_scores.empty?

      expected = Assessments::MadarakTemplate::CATEGORIES.keys
      valid = expected.all? do |code|
        valid_category_score?(@category_scores[code])
      end
      assessment.errors.add(:base, I18n.t("madarak_evaluations.errors.incomplete_scores")) unless valid
      valid
    end

    def apply_category_scores!(assessment)
      assessment.scores.includes(assessment_rubric_item: :assessment_category).find_each do |score|
        code = score.assessment_rubric_item.assessment_category.code
        next unless @category_scores.key?(code)

        value = @category_scores.fetch(code)
        if numeric_score?(value)
          score.update!(numeric_score: value)
        else
          score.update!(rating: value)
        end
      end
    end

    def valid_category_score?(value)
      AssessmentRubricItem::RATINGS.include?(value) || numeric_score?(value)
    end

    def numeric_score?(value)
      Float(value).between?(0, 100)
    rescue ArgumentError, TypeError
      false
    end

    def recalculate!(assessment)
      result = Assessments::GradeCalculator.new(scores: assessment.scores.includes(:assessment_rubric_item)).call
      assessment.update!(overall_score: result[:percentage], letter_grade: result[:letter_grade])
    end

    def event!(assessment, event_type, after_data: {})
      assessment.events.create!(actor: @actor, event_type:, after_data:)
    end

    def snapshot(assessment)
      assessment.attributes.slice("status", "assessment_date", "teacher_profile_id", "assessment_template_id")
    end

    def forbidden(assessment)
      assessment.errors.add(:base, :forbidden)
      assessment
    end
  end
end
