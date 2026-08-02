module Teacher
  class StudentAssessmentsQuery
    def initialize(teacher_profile:, params:, relation: StudentAssessment.all)
      @teacher_profile = teacher_profile
      @params = params
      @relation = relation
    end

    def call
      scope = @relation.where(teacher_profile: @teacher_profile)
                       .includes(:assessment_template, student_profile: :user)
      scope = scope.where(status: @params[:status]) if StudentAssessment::STATUSES.include?(@params[:status])
      scope.recent_first
    end
  end
end
