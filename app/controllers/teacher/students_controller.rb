module Teacher
  class StudentsController < BaseController
    def show
      scope = StudentLearningProfiles::Access.new(current_user).student_scope
      @student = scope.includes(:user, :assigned_teacher_profile).find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end
  end
end
