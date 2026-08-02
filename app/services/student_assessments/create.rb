module StudentAssessments
  class Create
    def initialize(actor:, attributes:)
      @actor = actor
      @attributes = attributes
    end

    def call
      assessment = StudentAssessment.new(@attributes)
      assessment.student_profile = assessment.enrollment&.student_profile
      assessment.created_by = assessment.updated_by = @actor
      return forbidden(assessment) unless authorized?(assessment)

      StudentAssessment.transaction do
        assessment.save!
        initialize_scores!(assessment)
        event!(assessment, "created", after_data: snapshot(assessment))
      end
      assessment
    rescue ActiveRecord::RecordInvalid
      assessment
    end

    private

    def authorized?(assessment)
      return false unless @actor.active?
      return true if @actor.admin?

      @actor.teacher? && assessment.teacher_profile&.user_id == @actor.id && assigned_enrollment?(assessment)
    end

    def assigned_enrollment?(assessment)
      ScheduledLesson.exists?(teacher_profile: assessment.teacher_profile,
                              course_offering_id: assessment.enrollment&.course_offering_id)
    end

    def initialize_scores!(assessment)
      assessment.assessment_template.rubric_items.find_each do |rubric|
        assessment.scores.create!(assessment_rubric_item: rubric)
      end
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
