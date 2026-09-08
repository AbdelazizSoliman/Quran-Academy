module Student
  class AcademicRecordsQuery
    VISIBLE_ASSESSMENT_STATUSES = %w[submitted reviewed published].freeze

    def initialize(student_profile:)
      @student_profile = student_profile
    end

    def assessments
      StudentAssessment.where(student_profile: @student_profile, status: VISIBLE_ASSESSMENT_STATUSES)
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
