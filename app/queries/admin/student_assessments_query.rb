module Admin
  class StudentAssessmentsQuery
    SORTS = { "date" => "student_assessments.assessment_date", "score" => "student_assessments.overall_score",
              "created" => "student_assessments.created_at" }.freeze

    def initialize(params:, relation: StudentAssessment.all)
      @params = params
      @relation = relation
    end

    def call
      scope = @relation.includes(:assessment_template, teacher_profile: :user, student_profile: :user)
                       .where(assessment_date: date_range)
      scope = scope.where(status: @params[:status]) if StudentAssessment::STATUSES.include?(@params[:status])
      scope = scope.where(teacher_profile_id: @params[:teacher_id]) if @params[:teacher_id].present?
      scope = scope.where(student_profile_id: @params[:student_id]) if @params[:student_id].present?
      scope = scope.where(assessment_template_id: @params[:template_id]) if @params[:template_id].present?
      order(scope)
    end

    private

    def date_range
      (parse_date(@params[:from]) || 6.months.ago.to_date)..(parse_date(@params[:to]) || Date.current)
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def order(scope)
      column = SORTS.fetch(@params[:sort], SORTS["date"])
      direction = @params[:direction] == "asc" ? "ASC" : "DESC"
      scope.order(Arel.sql("#{column} #{direction}"), id: :desc)
    end
  end
end
