module Admin
  class TeachersQuery
    COMPLETION_SQL = <<~SQL.squish.freeze
      CASE WHEN display_name IS NULL OR display_name = '' THEN 0 ELSE 1 END +
      CASE WHEN bio IS NULL OR bio = '' THEN 0 ELSE 1 END +
      CASE WHEN phone_number IS NULL AND whatsapp_number IS NULL THEN 0 ELSE 1 END +
      CASE WHEN country_of_residence IS NULL OR country_of_residence = '' THEN 0 ELSE 1 END +
      CASE WHEN cardinality(teaching_languages) > 0 THEN 1 ELSE 0 END +
      CASE WHEN cardinality(student_age_groups) > 0 THEN 1 ELSE 0 END +
      CASE WHEN cardinality(teaching_specializations) > 0 THEN 1 ELSE 0 END +
      CASE WHEN years_of_teaching_experience IS NULL THEN 0 ELSE 1 END +
      CASE WHEN employment_status IS NULL OR employment_status = '' THEN 0 ELSE 1 END +
      CASE WHEN default_lesson_rate IS NULL OR compensation_currency IS NULL OR compensation_unit IS NULL
        THEN 0 ELSE 1 END
    SQL
    SORT_COLUMNS = {
      "name" => "teacher_profiles.display_name",
      "public_id" => "teacher_profiles.public_id",
      "created_at" => "teacher_profiles.created_at",
      "joined_on" => "teacher_profiles.joined_on",
      "experience" => "teacher_profiles.years_of_teaching_experience",
      "employment_status" => "teacher_profiles.employment_status",
      "completion" => COMPLETION_SQL
    }.freeze
    SORTS = SORT_COLUMNS.keys.index_with do |key|
      {
        "asc" => Arel.sql("#{SORT_COLUMNS.fetch(key)} ASC, teacher_profiles.id DESC"),
        "desc" => Arel.sql("#{SORT_COLUMNS.fetch(key)} DESC, teacher_profiles.id DESC")
      }.freeze
    end.freeze

    def initialize(params:, scope: TeacherProfile.all)
      @params = params
      @scope = scope
    end

    def call
      relation = @scope.left_joins(:user).includes(:user)
      relation = search(relation)
      relation = filters(relation)
      relation.order(ordering)
    end

    private

    def search(relation)
      term = @params[:q].to_s.strip
      return relation if term.blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
      relation.where(
        "teacher_profiles.public_id ILIKE :q OR teacher_profiles.display_name ILIKE :q OR " \
        "users.first_name ILIKE :q OR users.last_name ILIKE :q OR users.email ILIKE :q OR " \
        "teacher_profiles.phone_number ILIKE :q OR teacher_profiles.whatsapp_number ILIKE :q", q: pattern
      )
    end

    def filters(relation)
      relation = scalar_filters(relation)
      array_filters(relation)
    end

    def scalar_filters(relation)
      filtered = valid_user_status? ? relation.where(users: { status: @params[:user_status] }) : relation
      %i[employment_status engagement_type profile_status].each do |attribute|
        value = @params[attribute]
        catalog = TeacherProfile.const_get(attribute.to_s.pluralize.upcase)
        filtered = filtered.where(attribute => value) if value.to_s.in?(catalog)
      end
      filtered
    end

    def array_filters(relation)
      filtered = array_filter(relation, :teaching_language, "? = ANY(teaching_languages)")
      filtered = array_filter(filtered, :specialization, "? = ANY(teaching_specializations)")
      array_filter(filtered, :age_group, "? = ANY(student_age_groups)")
    end

    def array_filter(relation, param, sql)
      value = @params[param].to_s
      return relation unless value.in?(filter_catalog(param))

      relation.where(sql, value)
    end

    def valid_user_status?
      @params[:user_status].to_s.in?(User.statuses.keys)
    end

    def filter_catalog(param)
      {
        teaching_language: AcademySetting.current_or_nil&.teaching_languages || [],
        specialization: TeacherProfile::SPECIALIZATIONS,
        age_group: TeacherProfile::AGE_GROUPS
      }.fetch(param)
    end

    def ordering
      sort = SORTS.fetch(@params[:sort].to_s, SORTS.fetch("created_at"))
      sort.fetch(@params[:direction].to_s, sort.fetch("desc"))
    end
  end
end
