module Admin
  class LessonAttendancesQuery
    SORTS = { "lesson" => "scheduled_lessons.starts_at", "arrival" => "lesson_attendances.arrival_at",
              "status" => "lesson_attendances.status", "student" => "student_profiles.display_name" }.freeze

    def initialize(params:, relation: LessonAttendance.all)
      @params = params
      @relation = relation
    end

    def call
      scope = base_scope.where(scheduled_lessons: { starts_at: date_range })
      scope = apply_status(scope)
      scope = apply_teacher(scope)
      scope = apply_flags(scope)
      scope.order(sort_column => direction, "lesson_attendances.id" => :asc)
    end

    private

    def base_scope
      @relation.joins(scheduled_lesson_enrollment: { enrollment: :student_profile },
                      scheduled_lesson: [:teacher_profile, { course_offering: :program }])
               .includes(:recorded_by, :last_adjusted_by, scheduled_lesson_enrollment: { enrollment: :student_profile },
                                                          scheduled_lesson: %i[teacher_profile course_offering])
    end

    def date_range
      from = parse_date(@params[:from]) || Date.current.beginning_of_week
      to = parse_date(@params[:to]) || Date.current.end_of_week
      from.beginning_of_day..to.end_of_day
    end

    def apply_status(scope)
      LessonAttendance::STATUSES.include?(@params[:status]) ? scope.where(status: @params[:status]) : scope
    end

    def apply_teacher(scope)
      return scope unless teacher_filter?

      scope.where(scheduled_lessons: { teacher_profile_id: @params[:teacher_profile_id] })
    end

    def apply_flags(scope)
      scope = scope.where(status: "pending") if truthy?(:unresolved_only)
      scope = scope.where("lesson_attendances.minutes_late > 0") if truthy?(:late_only)
      truthy?(:absent_only) ? scope.where(status: %w[absent excused_absence]) : scope
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def teacher_filter? = @params[:teacher_profile_id].present?
    def truthy?(key) = ActiveModel::Type::Boolean.new.cast(@params[key])
    def sort_column = SORTS.fetch(@params[:sort].to_s, SORTS.fetch("lesson"))
    def direction = %w[asc desc].include?(@params[:direction]) ? @params[:direction] : "asc"
  end
end
