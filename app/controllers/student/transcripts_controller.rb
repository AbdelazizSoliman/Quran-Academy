module Student
  class TranscriptsController < BaseController
    def show
      query = AcademicRecordsQuery.new(student_profile: current_user.student_profile)
      @enrollments = query.enrollments
      @assessments = query.assessments
      @certificates = query.certificates
      @progress = current_user.student_profile.student_progress
    end
  end
end
