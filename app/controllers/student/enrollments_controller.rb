module Student
  class EnrollmentsController < BaseController
    def index
      profile = current_user.student_profile
      @enrollments = if profile
                       profile.enrollments.includes(course_offering: :program).recent_first
                     else
                       Enrollment.none
                     end
    end

    def show
      profile = current_user.student_profile
      return head :not_found unless profile

      @enrollment = profile.enrollments.includes(course_offering: :program).find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end
  end
end
