module ExamSessions
  class Create
    def initialize(actor:, attributes:)
      @actor = actor
      @attributes = attributes
    end

    def call
      exam = ExamSession.new(@attributes.merge(created_by: @actor, updated_by: @actor))
      return forbidden(exam) unless @actor.active? && @actor.admin?

      ExamSession.transaction do
        exam.save!
        exam.events.create!(actor: @actor, event_type: "created", after_data: exam.attributes.slice("status", "starts_at"))
      end
      exam
    rescue ActiveRecord::RecordInvalid
      exam
    end

    private

    def forbidden(exam)
      exam.errors.add(:base, :forbidden)
      exam
    end
  end
end
