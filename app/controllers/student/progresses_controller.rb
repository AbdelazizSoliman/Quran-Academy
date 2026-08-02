module Student
  class ProgressesController < BaseController
    def show
      @progress = current_user.student_profile.student_progress
      @assessments = AcademicRecordsQuery.new(student_profile: current_user.student_profile).assessments.limit(10)
    end
  end
end
