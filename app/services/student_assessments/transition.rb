module StudentAssessments
  class Transition
    TRANSITIONS = {
      submit: { from: "draft", to: "submitted", timestamp: :submitted_at, event: "submitted" },
      review: { from: "submitted", to: "reviewed", timestamp: :reviewed_at, event: "reviewed" },
      publish: { from: "reviewed", to: "published", timestamp: :published_at, event: "published" },
      archive: { from: "published", to: "archived", timestamp: :archived_at, event: "archived" }
    }.freeze

    def initialize(actor:, assessment:, action:)
      @actor = actor
      @assessment = assessment
      @action = action.to_sym
    end

    def call
      rule = TRANSITIONS.fetch(@action)
      return @assessment if @assessment.status == rule[:to]
      return invalid(:forbidden) unless authorized?
      return invalid(:invalid_transition) unless @assessment.status == rule[:from]
      return invalid(:incomplete_scores) if @action == :submit && incomplete_scores?

      transition!(rule)
    rescue KeyError
      invalid(:invalid_transition)
    rescue ActiveRecord::StaleObjectError
      invalid(:stale_record)
    end

    private

    def authorized?
      return @actor.active? && @actor.admin? unless @action == :submit

      @actor.active? && (@actor.admin? || (@actor.teacher? && @assessment.teacher_profile.user_id == @actor.id))
    end

    def incomplete_scores?
      @assessment.assessment_template.rubric_items.where(required: true).any? do |rubric|
        score = @assessment.scores.find { |entry| entry.assessment_rubric_item_id == rubric.id }
        score.nil? || (score.numeric_score.nil? && score.rating.blank?)
      end
    end

    def transition!(rule)
      StudentAssessment.transaction do
        previous = @assessment.status
        now = Time.current
        attributes = { status: rule[:to], rule[:timestamp] => now, updated_by: @actor }
        attributes[:reviewer] = @actor if @action == :review
        @assessment.update!(attributes)
        @assessment.events.create!(actor: @actor, event_type: rule[:event],
                                   before_data: { "status" => previous }, after_data: { "status" => rule[:to] })
        StudentProgresses::Recalculate.new(student_profile: @assessment.student_profile,
                                           actor: @actor).call if @action.in?(%i[publish archive])
      end
      @assessment
    end

    def invalid(key)
      @assessment.errors.add(:base, key)
      @assessment
    end
  end
end
