module Admin
  class MadarakStudentsQuery
    SORT_COLUMNS = StudentsQuery::SORT_COLUMNS
    SORTS = StudentsQuery::SORTS

    def initialize(params:, relation: StudentProfile.all)
      @params = params
      @relation = relation
    end

    def call
      relation = @relation.includes(:user, :assigned_teacher_profile, student_guardianships: :guardian)
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

      {
        student_type: StudentProfile::STUDENT_TYPES,
        profile_status: StudentProfile::PROFILE_STATUSES,
        learning_status: StudentProfile::LEARNING_STATUSES,
        preferred_learning_language: AcademySetting::TEACHING_LANGUAGES,
        current_quran_level: StudentProfile::QURAN_LEVELS,
        gender: StudentProfile::GENDERS,
        billing_currency: StudentProfile::CURRENCIES
      }.each do |field, values|
        relation = relation.where(field => @params[field]) if values.include?(@params[field])
      end

      if @params[:teacher_id].to_s.match?(/\A\d+\z/)
        relation = relation.where(assigned_teacher_profile_id: @params[:teacher_id])
      end
      relation = relation.where(country_of_residence: @params[:country]) if @params[:country].present?
      relation = age_filter(relation)

      case @params[:guardian]
      when "present" then relation.joins(:student_guardianships)
      when "missing" then relation.where.missing(:student_guardianships)
      else relation
      end
    end

    def age_filter(relation)
      case @params[:age_group]
      when "under_13"
        relation.where(date_of_birth: 13.years.ago.to_date.next_day..Date.current)
      when "13_17"
        relation.where(date_of_birth: 18.years.ago.to_date.next_day..13.years.ago.to_date)
      when "18_plus"
        relation.where(date_of_birth: ..18.years.ago.to_date)
      else
        relation
      end
    end

    def ordering
      SORTS.fetch(@params[:sort].to_s, SORTS.fetch("created_at"))
           .fetch(@params[:direction].to_s, SORTS.fetch("created_at").fetch("desc"))
    end
  end
end
