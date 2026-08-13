module Parent
  class BaseController < ApplicationController
    before_action :require_guardian!

    private

    def require_guardian!
      return if current_user&.active? && current_user.guardian?

      render plain: t("authorization.forbidden"), status: :forbidden
    end

    def guardian_profile
      @guardian_profile ||= current_user.guardian_profile
    end

    def guardian_students
      return StudentProfile.none unless guardian_profile

      StudentProfile.joins(:student_guardianships)
                    .where(student_guardianships: { guardian_id: guardian_profile.id, status: "active" })
                    .distinct
    end

    def set_guardian_student
      @student = guardian_students.includes(:user, :student_progress).find(params.expect(:id))
    end
  end
end
