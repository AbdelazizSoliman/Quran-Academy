module StudentObservations
  class Create
    FIELDS = %w[category observation observed_at visibility sensitivity source scheduled_lesson_id].freeze

    def initialize(actor:, student_profile:, teacher_profile:, attributes:)
      @actor = actor
      @student_profile = student_profile
      @teacher_profile = teacher_profile
      @attributes = attributes.to_h.stringify_keys.slice(*FIELDS)
    end

    def call
      attributes = @attributes.merge(student_profile: @student_profile, teacher_profile: @teacher_profile,
                                     created_by: @actor, source: source)
      observation = StudentObservation.new(attributes)
      return forbidden(observation) unless authorized?(observation)

      observation.save
      observation
    end

    private

    def authorized?(observation)
      access = StudentLearningProfiles::Access.new(@actor)
      return false unless access.can_write?(@student_profile)
      return true if access.can_manage_highly_sensitive?
      return false unless @teacher_profile.user_id == @actor.id
      return false if observation.sensitivity == "highly_sensitive"

      observation.sensitivity == "standard" || observation.visibility == "internal"
    end

    def source = @actor.admin? ? "admin_entry" : "teacher_entry"

    def forbidden(observation)
      observation.errors.add(:base, :forbidden)
      observation
    end
  end
end
