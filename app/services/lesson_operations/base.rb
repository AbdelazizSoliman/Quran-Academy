module LessonOperations
  class Base
    def initialize(actor:, lesson:)
      @actor = actor
      @lesson = lesson
    end

    private

    def assigned_teacher?
      profile = @lesson.teacher_profile
      @actor.active? && @actor.teacher? && profile.user_id == @actor.id &&
        profile.employment_status == "active" && !profile.archived?
    end

    def administrator? = @actor.active? && @actor.admin?

    def authorize_teacher_or_admin!
      return if assigned_teacher? || administrator?

      @lesson.errors.add(:base, :forbidden)
      throw :abort
    end

    def event!(type, before_data: {}, after_data: {}, metadata: {})
      ScheduledLessonEvent.create!(scheduled_lesson: @lesson, actor: @actor, event_type: type,
                                   before_data:, after_data:, metadata:)
    end

    def failed(error)
      @lesson.errors.add(:base, error)
      @lesson
    end
  end
end
