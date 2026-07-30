module Admin
  class CourseOfferingsQuery
    SORT_COLUMNS = {
      "title" => "course_offerings.title_en", "code" => "course_offerings.code",
      "program" => "programs.name_en", "status" => "course_offerings.status",
      "planned_start" => "course_offerings.planned_start_on",
      "enrollment_close" => "course_offerings.enrollment_closes_on",
      "capacity" => "course_offerings.capacity", "created_at" => "course_offerings.created_at"
    }.freeze
    SORTS = SORT_COLUMNS.keys.index_with do |key|
      %w[asc desc].index_with do |direction|
        Arel.sql("#{SORT_COLUMNS.fetch(key)} #{direction.upcase}, course_offerings.id DESC")
      end
    end.freeze

    def initialize(params:, relation: CourseOffering.all)
      @params = params
      @relation = relation
    end

    def call
      relation = search(@relation.joins(:program).includes(:program, :enrollments))
      relation = filters(relation)
      relation.distinct.order(ordering)
    end

    private

    def search(relation)
      return relation if @params[:q].blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@params[:q].strip)}%"
      relation.where(
        "course_offerings.public_id ILIKE :q OR course_offerings.code ILIKE :q OR " \
        "course_offerings.title_ar ILIKE :q OR course_offerings.title_en ILIKE :q OR " \
        "programs.name_ar ILIKE :q OR programs.name_en ILIKE :q OR programs.code ILIKE :q", q: pattern
      )
    end

    def filters(relation)
      filter_catalog(relation).then { |scope| filter_eligibility(scope) }
    end

    def filter_catalog(relation)
      scope = relation
      scope = scope.where(program_id: @params[:program_id]) if @params[:program_id].present?
      { status: CourseOffering::STATUSES, learning_language: AcademySetting::TEACHING_LANGUAGES,
        delivery_mode: CourseOffering::DELIVERY_MODES }.each do |field, values|
        scope = scope.where(field => @params[field]) if values.include?(@params[field])
      end
      scope
    end

    def filter_eligibility(relation)
      scope = relation
      if Program::AGE_GROUPS.include?(@params[:age_group])
        scope = scope.where("? = ANY(course_offerings.target_age_groups)", @params[:age_group])
      end
      scope = scope.where(placement_required: boolean(:placement_required)) unless boolean(:placement_required).nil?
      scope = scope.where(accepts_new_enrollments: boolean(:accepting)) unless boolean(:accepting).nil?
      return scope unless @params[:enrollment_window] == "current"

      scope.where(enrollment_closes_on: Date.current..)
    end

    def boolean(key)
      return true if @params[key] == "true"

      false if @params[key] == "false"
    end

    def ordering
      key = @params[:sort].to_s
      SORTS.fetch(key, SORTS.fetch("created_at"))
           .fetch(@params[:direction].to_s, SORTS.fetch("created_at").fetch("desc"))
    end
  end
end
