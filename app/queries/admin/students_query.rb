module Admin
  class StudentsQuery
    SORT_COLUMNS = {
      "name" => "student_profiles.display_name", "public_id" => "student_profiles.public_id",
      "created_at" => "student_profiles.created_at", "joined_on" => "student_profiles.joined_on",
      "date_of_birth" => "student_profiles.date_of_birth", "profile_status" => "student_profiles.profile_status",
      "learning_status" => "student_profiles.learning_status"
    }.freeze
    SORTS = SORT_COLUMNS.keys.index_with do |key|
      {
        "asc" => Arel.sql("#{SORT_COLUMNS.fetch(key)} ASC, student_profiles.id DESC"),
        "desc" => Arel.sql("#{SORT_COLUMNS.fetch(key)} DESC, student_profiles.id DESC")
      }.freeze
    end.freeze

    def initialize(params:, relation: StudentProfile.all)
      @params = params
      @relation = relation
    end

    def call
      relation = @relation.includes(:user, student_guardianships: :guardian)
      relation = search(relation)
      relation = filters(relation)
      relation.distinct.order(ordering)
    end

    private

    def search(relation)
      return relation if @params[:q].blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@params[:q].strip)}%"
      relation.left_joins(student_guardianships: :guardian).joins(:user).where(
        "student_profiles.public_id ILIKE :q OR student_profiles.display_name ILIKE :q OR " \
        "users.first_name ILIKE :q OR users.last_name ILIKE :q OR users.email ILIKE :q OR " \
        "student_profiles.phone_number ILIKE :q OR student_profiles.whatsapp_number ILIKE :q OR " \
        "guardians.full_name ILIKE :q OR guardians.email ILIKE :q OR guardians.phone_number ILIKE :q", q: pattern
      )
    end

    def filters(relation)
      if User.statuses.key?(@params[:user_status])
        relation = relation.joins(:user).where(users: { status: @params[:user_status] })
      end
      { student_type: StudentProfile::STUDENT_TYPES, profile_status: StudentProfile::PROFILE_STATUSES,
        learning_status: StudentProfile::LEARNING_STATUSES,
        preferred_learning_language: AcademySetting::TEACHING_LANGUAGES,
        current_quran_level: StudentProfile::QURAN_LEVELS }.each do |field, values|
        relation = relation.where(field => @params[field]) if values.include?(@params[field])
      end
      case @params[:guardian]
      when "present" then relation.joins(:student_guardianships)
      when "missing" then relation.where.missing(:student_guardianships)
      else relation
      end
    end

    def ordering
      SORTS.fetch(@params[:sort].to_s, SORTS.fetch("created_at"))
           .fetch(@params[:direction].to_s, SORTS.fetch("created_at").fetch("desc"))
    end
  end
end
