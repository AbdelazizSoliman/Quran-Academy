module Admin
  class ExamSessionsQuery
    def initialize(params:, relation: ExamSession.all)
      @params = params
      @relation = relation
    end

    def call
      scope = @relation.includes(:program, :course_offering, teacher_profile: :user)
      scope = scope.where(starts_at: date_range)
      scope = scope.where(status: @params[:status]) if ExamSession::STATUSES.include?(@params[:status])
      scope = scope.where(teacher_profile_id: @params[:teacher_id]) if @params[:teacher_id].present?
      scope.order(starts_at: :desc, id: :desc)
    end

    private

    def date_range
      (parse(@params[:from]) || 3.months.ago.to_date).beginning_of_day..
        (parse(@params[:to]) || 6.months.from_now.to_date).end_of_day
    end

    def parse(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
  end
end
