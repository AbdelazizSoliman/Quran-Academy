module StudentLearningProfiles
  class EnsureExists
    def initialize(actor:, student_profile:)
      @actor = actor
      @student_profile = student_profile
    end

    def call
      return forbidden_profile unless access.can_write?(@student_profile)
      return @student_profile.student_learning_profile if @student_profile.student_learning_profile

      StudentLearningProfile.transaction do
        profile = StudentLearningProfile.create!(student_profile: @student_profile, created_by: @actor,
                                                 updated_by: @actor)
        profile.events.create!(actor: @actor, action: "profile_created", source: source)
        profile
      end
    rescue ActiveRecord::RecordNotUnique
      @student_profile.reload.student_learning_profile
    end

    private

    def access = @access ||= Access.new(@actor)
    def source = @actor.admin? ? "admin_entry" : "teacher_entry"

    def forbidden_profile
      profile = StudentLearningProfile.new(student_profile: @student_profile, created_by: @actor, updated_by: @actor)
      profile.errors.add(:base, :forbidden)
      profile
    end
  end
end
