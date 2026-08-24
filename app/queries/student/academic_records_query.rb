module Student
  class AcademicRecordsQuery
    def initialize(student_profile:)
      @student_profile = student_profile
    end

    def assessments
      StudentAssessment.where(student_profile: @student_profile, status: %w[submitted reviewed published])
                       .includes(:assessment_template, :teacher_profile).recent_first
    end

    def certificates
      Certificate.where(student_profile: @student_profile).includes(:enrollment, :exam_session).recent_first
    end

    def enrollments
      @student_profile.enrollments.includes(course_offering: :program).order(created_at: :desc)
    end
  end
end
