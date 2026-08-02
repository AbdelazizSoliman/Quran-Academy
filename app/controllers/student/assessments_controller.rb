module Student
  class AssessmentsController < BaseController
    def index
      @assessments = query.assessments
    end

    def show
      @assessment = query.assessments.includes(scores: { assessment_rubric_item: :assessment_category })
                         .find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def query = AcademicRecordsQuery.new(student_profile: current_user.student_profile)
  end
end
