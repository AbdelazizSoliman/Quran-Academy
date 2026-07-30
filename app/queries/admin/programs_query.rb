module Admin
  class ProgramsQuery
    SORT_COLUMNS = {
      "display_order" => "programs.display_order", "name" => "programs.name_en",
      "code" => "programs.code", "status" => "programs.status", "created_at" => "programs.created_at",
      "offerings_count" => "COUNT(DISTINCT course_offerings.id)"
    }.freeze
    SORTS = SORT_COLUMNS.keys.index_with do |key|
      %w[asc desc].index_with do |direction|
        Arel.sql("#{SORT_COLUMNS.fetch(key)} #{direction.upcase}, programs.id DESC")
      end
    end.freeze

    def initialize(params:, relation: Program.all)
      @params = params
      @relation = relation
    end

    def call
      relation = search(@relation.includes(:course_offerings))
      relation = filters(relation)
      return relation.left_joins(:course_offerings).group("programs.id").order(ordering) if sort == "offerings_count"

      relation.distinct.order(ordering)
    end

    private

    def search(relation)
      return relation if @params[:q].blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@params[:q].strip)}%"
      relation.where(
        "programs.public_id ILIKE :q OR programs.code ILIKE :q OR programs.name_ar ILIKE :q OR " \
        "programs.name_en ILIKE :q OR programs.description_ar ILIKE :q OR programs.description_en ILIKE :q", q: pattern
      )
    end

    def filters(relation)
      filter_catalog(relation).then { |scope| filter_arrays(scope) }.then { |scope| filter_flags(scope) }
    end

    def filter_catalog(relation)
      catalog = { category: Program::CATEGORIES, status: Program::STATUSES,
                  default_learning_language: AcademySetting::TEACHING_LANGUAGES }
      catalog.each_with_object(relation) do |(field, values), scope|
        next scope unless values.include?(@params[field])

        scope.where(field => @params[field])
      end
    end

    def filter_arrays(relation)
      scope = relation
      if AcademySetting::TEACHING_LANGUAGES.include?(@params[:language])
        scope = scope.where("? = ANY(supported_learning_languages)", @params[:language])
      end
      return scope unless Program::AGE_GROUPS.include?(@params[:age_group])

      scope.where("? = ANY(target_age_groups)", @params[:age_group])
    end

    def filter_flags(relation)
      scope = relation
      { placement_required: :placement_required, minor_allowed: :allows_minor_students,
        adult_allowed: :allows_adult_students }.each do |parameter, field|
        value = boolean(parameter)
        scope = scope.where(field => value) unless value.nil?
      end
      scope
    end

    def boolean(key)
      return true if @params[key] == "true"

      false if @params[key] == "false"
    end

    def sort = @params[:sort].to_s

    def ordering
      SORTS.fetch(sort, SORTS.fetch("display_order"))
           .fetch(@params[:direction].to_s, SORTS.fetch("display_order").fetch("asc"))
    end
  end
end
