module Parent
  class ProfilesController < BaseController
    def show
      @guardian = guardian_profile
      @guardianships = @guardian&.student_guardianships&.active&.includes(student_profile: :user) || []
    end
  end
end
