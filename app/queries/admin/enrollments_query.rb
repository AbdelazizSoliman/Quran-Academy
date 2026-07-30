module Admin
  class EnrollmentsQuery
    SORT_COLUMNS = {
      "public_id" => "enrollments.public_id", "student" => "student_profiles.display_name",
      "program" => "programs.name_en", "offering" => "course_offerings.title_en",
      "status" => "enrollments.status", "applied_on" => "enrollments.applied_on",
      "approved_on" => "enrollments.approved_on", "started_on" => "enrollments.started_on",
      "created_at" => "enrollments.created_at"
    }.freeze
    SORTS = SORT_COLUMNS.keys.index_with do |key|
      %w[asc desc].index_with do |direction|
        Arel.sql("#{SORT_COLUMNS.fetch(key)} #{direction.upcase}, enrollments.id DESC")
      end
    end.freeze

    def initialize(params:, relation: Enrollment.all)
      @params = params
      @relation = relation
    end

    def call
      relation = @relation.joins(student_profile: :user, course_offering: :program)
                          .includes(student_profile: :user, course_offering: :program)
      relation = search(relation)
      relation = filters(relation)
      relation.distinct.order(ordering)
    end

    private

    def search(relation)
      return relation if @params[:q].blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@params[:q].strip)}%"
      relation.where(
        "enrollments.public_id ILIKE :q OR student_profiles.public_id ILIKE :q OR " \
        "student_profiles.display_name ILIKE :q OR users.email ILIKE :q OR " \
        "course_offerings.public_id ILIKE :q OR course_offerings.code ILIKE :q OR " \
        "programs.name_ar ILIKE :q OR programs.name_en ILIKE :q", q: pattern
      )
    end

    def filters(relation)
      filter_statuses(relation).then { |scope| filter_ownership(scope) }.then { |scope| filter_dates(scope) }
    end

    def filter_statuses(relation)
      scope = relation
      scope = scope.where(status: @params[:status]) if Enrollment::STATUSES.include?(@params[:status])
      if Enrollment::PLACEMENT_STATUSES.include?(@params[:placement_status])
        scope = scope.where(placement_status: @params[:placement_status])
      end
      return scope unless Enrollment::APPLICATION_SOURCES.include?(@params[:application_source])

      scope.where(application_source: @params[:application_source])
    end

    # Each ownership filter is independently allowlisted to keep query input safe.
    # rubocop:disable Metrics/AbcSize
    def filter_ownership(relation)
      scope = relation
      scope = scope.where(course_offerings: { program_id: @params[:program_id] }) if @params[:program_id].present?
      scope = scope.where(course_offering_id: @params[:course_offering_id]) if @params[:course_offering_id].present?
      if StudentProfile::STUDENT_TYPES.include?(@params[:student_type])
        scope = scope.where(student_profiles: { student_type: @params[:student_type] })
      end
      if AcademySetting::TEACHING_LANGUAGES.include?(@params[:learning_language])
        scope = scope.where(course_offerings: { learning_language: @params[:learning_language] })
      end
      scope
    end
    # rubocop:enable Metrics/AbcSize

    def filter_dates(relation)
      scope = relation
      scope = scope.where(status: Enrollment::TERMINAL_STATUSES) if @params[:terminal] == "true"
      scope = scope.where.not(status: Enrollment::TERMINAL_STATUSES) if @params[:terminal] == "false"
      scope = scope.where(applied_on: Date.iso8601(@params[:applied_on])..) if valid_date?(@params[:applied_on])
      scope.where(started_on: Date.iso8601(@params[:started_on])..) if valid_date?(@params[:started_on])
    end

    def valid_date?(value)
      Date.iso8601(value.to_s)
      true
    rescue Date::Error
      false
    end

    def ordering
      key = @params[:sort].to_s
      SORTS.fetch(key, SORTS.fetch("created_at"))
           .fetch(@params[:direction].to_s, SORTS.fetch("created_at").fetch("desc"))
    end
  end
end
