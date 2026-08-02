module ExamSessions
  class Transition
    TRANSITIONS = {
      schedule: %w[draft scheduled], complete: %w[scheduled completed], review: %w[completed reviewed],
      publish: %w[reviewed published], archive: %w[published archived]
    }.freeze

    def initialize(actor:, exam_session:, action:)
      @actor = actor
      @exam = exam_session
      @action = action.to_sym
    end

    def call
      from, to = TRANSITIONS.fetch(@action)
      return @exam if @exam.status == to
      return invalid(:forbidden) unless authorized?
      return invalid(:invalid_transition) unless @exam.status == from

      ExamSession.transaction do
        @exam.update!(status: to, updated_by: @actor)
        @exam.events.create!(actor: @actor, event_type: @action.to_s,
                             before_data: { "status" => from }, after_data: { "status" => to })
      end
      @exam
    rescue KeyError
      invalid(:invalid_transition)
    rescue ActiveRecord::StaleObjectError
      invalid(:stale_record)
    end

    private

    def authorized?
      @actor.active? && (@actor.admin? || (@actor.teacher? && @exam.teacher_profile.user_id == @actor.id &&
        @action.in?(%i[complete])))
    end

    def invalid(key)
      @exam.errors.add(:base, key)
      @exam
    end
  end
end
