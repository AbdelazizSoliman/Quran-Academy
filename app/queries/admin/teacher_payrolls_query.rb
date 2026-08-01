module Admin
  class TeacherPayrollsQuery
    def initialize(params:, relation: TeacherPayroll.all)
      @params = params
      @relation = relation
    end

    def call
      scope = @relation.includes(teacher_profile: :user).where(period_starts_on: date_range)
      scope = scope.where(teacher_profile_id: @params[:teacher_id]) if @params[:teacher_id].present?
      scope = scope.where(status: @params[:status]) if TeacherPayroll::STATUSES.include?(@params[:status])
      scope.recent_first
    end

    private

    def date_range
      from = parse_date(@params[:from]) || 1.year.ago.to_date
      to = parse_date(@params[:to]) || Date.current
      from..to
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
  end
end
