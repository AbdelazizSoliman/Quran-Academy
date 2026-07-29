module Admin
  class GuardiansQuery
    SORT_COLUMNS = {
      "name" => "guardians.full_name", "public_id" => "guardians.public_id",
      "created_at" => "guardians.created_at", "status" => "guardians.status",
      "students_count" => "COUNT(DISTINCT student_guardianships.student_profile_id)"
    }.freeze
    SORTS = SORT_COLUMNS.keys.index_with do |key|
      {
        "asc" => Arel.sql("#{SORT_COLUMNS.fetch(key)} ASC, guardians.id DESC"),
        "desc" => Arel.sql("#{SORT_COLUMNS.fetch(key)} DESC, guardians.id DESC")
      }.freeze
    end.freeze

    def initialize(params:, relation: Guardian.all)
      @params = params
      @relation = relation
    end

    def call
      relation = @relation.includes(student_guardianships: :student_profile)
      relation = search(relation)
      relation = relation.where(status: @params[:status]) if Guardian::STATUSES.include?(@params[:status])
      if Guardian::CONTACT_METHODS.include?(@params[:preferred_contact_method])
        relation = relation.where(preferred_contact_method: @params[:preferred_contact_method])
      end
      if Guardian::LANGUAGES.include?(@params[:preferred_language])
        relation = relation.where(preferred_language: @params[:preferred_language])
      end
      if sort == "students_count"
        return relation.left_joins(:student_guardianships).group("guardians.id").order(ordering)
      end

      relation.distinct.order(ordering)
    end

    private

    def search(relation)
      return relation if @params[:q].blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@params[:q].strip)}%"
      relation.left_joins(student_guardianships: :student_profile).where(
        "guardians.public_id ILIKE :q OR guardians.full_name ILIKE :q OR guardians.email ILIKE :q OR " \
        "guardians.phone_number ILIKE :q OR guardians.whatsapp_number ILIKE :q OR " \
        "student_profiles.public_id ILIKE :q OR student_profiles.display_name ILIKE :q", q: pattern
      )
    end

    def sort = @params[:sort].to_s

    def ordering
      SORTS.fetch(sort, SORTS.fetch("created_at"))
           .fetch(@params[:direction].to_s, SORTS.fetch("created_at").fetch("desc"))
    end
  end
end
