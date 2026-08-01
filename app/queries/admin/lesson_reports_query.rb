module Admin
  class LessonReportsQuery
    def initialize(params:, relation: LessonReport.all)
      @params = params
      @relation = relation
    end

    def call
      scope = @relation.joins(:scheduled_lesson).includes(:teacher_profile, scheduled_lesson: :course_offering,
                                                                            lesson_student_reports: [])
      scope = scope.where(scheduled_lessons: { starts_at: date_range })
      scope = scope.where(status: @params[:status]) if LessonReport::STATUSES.include?(@params[:status])
      scope.order("scheduled_lessons.starts_at" => :desc, "lesson_reports.id" => :desc)
    end

    private

    def date_range
      from = parse_date(@params[:from]) || Date.current.beginning_of_month
      to = parse_date(@params[:to]) || Date.current.end_of_month
      from.beginning_of_day..to.end_of_day
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
  end
end
