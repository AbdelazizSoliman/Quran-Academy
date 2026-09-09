module PublicCatalog
  # Bounded, allowlisted access to Programs that are safe to render on the public website.
  # Only publicly approved columns are selected, so operational fields such as internal notes,
  # audit ownership, and the operational public_id can never reach a public view.
  class ProgramsQuery
    PUBLIC_COLUMNS = %i[
      id slug_ar slug_en public_featured public_display_order
      name_ar name_en short_description_ar short_description_en description_ar description_en
      category target_age_groups supported_learning_languages default_learning_language
      default_lesson_duration_minutes recommended_lessons_per_week estimated_duration_weeks
      entry_level completion_level requires_placement
    ].freeze
    INDEX_LIMIT = 60
    FEATURED_LIMIT = 3
    SLUG_COLUMNS = { "ar" => :slug_ar, "en" => :slug_en }.freeze
    NAME_COLUMNS = { "ar" => :name_ar, "en" => :name_en }.freeze

    def initialize(locale:)
      @locale = locale.to_s == "ar" ? "ar" : "en"
    end

    def index(limit: INDEX_LIMIT)
      base.limit(limit)
    end

    def available? = Program.publicly_visible.exists?

    def featured(limit: FEATURED_LIMIT)
      base.where(public_featured: true).limit(limit)
    end

    def find_published_by_slug(slug)
      normalized = Program.normalize_public_slug(slug)
      return if normalized.blank?

      base.find_by(SLUG_COLUMNS.fetch(@locale) => normalized)
    end

    private

    def base
      Program.publicly_visible.select(PUBLIC_COLUMNS).order(
        public_display_order: :asc, NAME_COLUMNS.fetch(@locale) => :asc, id: :asc
      )
    end
  end
end
