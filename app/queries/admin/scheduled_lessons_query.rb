module Admin
  class ScheduledLessonsQuery
    SORTS = {
      "starts_at" => "scheduled_lessons.starts_at",
      "teacher" => "teacher_profiles.display_name",
      "status" => "scheduled_lessons.status",
      "created_at" => "scheduled_lessons.created_at"
    }.freeze
    SEARCH_SQL = <<~SQL.squish
      scheduled_lessons.public_id ILIKE :q OR scheduled_lessons.title_ar ILIKE :q OR
      scheduled_lessons.title_en ILIKE :q OR programs.name_ar ILIKE :q OR programs.name_en ILIKE :q
    SQL

    def initialize(params:, relation: ScheduledLesson.all)
      @params = params
      @relation = relation
    end

    def call
      scope = @relation.joins(:teacher_profile, course_offering: :program)
                       .includes(:teacher_profile, :course_offering, :enrollments)
      scope = search(scope)
      scope = filters(scope)
      scope.distinct.order(sort_column => direction, "scheduled_lessons.id" => :asc)
    end

    private

    def search(scope)
      return scope if @params[:q].blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@params[:q].to_s.strip)}%"
      scope.where(SEARCH_SQL, q: pattern)
    end

    def filters(scope)
      filter_status(scope)
        .then { |relation| filter_value(relation, :teacher_profile_id) }
        .then { |relation| filter_value(relation, :course_offering_id) }
        .then { |relation| filter_delivery_mode(relation) }
        .where(starts_at: date_range)
    end

    def filter_status(scope)
      return scope if @params[:status].blank?

      scope.where(status: ScheduledLesson::STATUSES & Array(@params[:status]))
    end

    def filter_value(scope, attribute)
      @params[attribute].present? ? scope.where(attribute => @params[attribute]) : scope
    end

    def filter_delivery_mode(scope)
      return scope unless ScheduledLesson::DELIVERY_MODES.include?(@params[:delivery_mode])

      scope.where(delivery_mode: @params[:delivery_mode])
    end

    def date_range
      from = parse_date(@params[:from]) || Date.current.beginning_of_week
      to = parse_date(@params[:to]) || (from + 30.days)
      from.beginning_of_day..to.end_of_day
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def sort = @params[:sort].to_s
    def sort_column = SORTS.fetch(sort, SORTS.fetch("starts_at"))
    def direction = %w[asc desc].include?(@params[:direction]) ? @params[:direction] : "asc"
  end
end
