module PublicCatalog
  # Bounded, allowlisted access to FeePlans that are safe to render on the public website.
  # Operational billing mechanics (public_id, invoice_day, tax_percentage, audit ownership,
  # student associations) are never selected.
  class FeePlansQuery
    PUBLIC_COLUMNS = %i[
      id public_display_order name_ar name_en description_ar description_en
      public_features_ar public_features_en price_note_ar price_note_en
      public_cta_label_ar public_cta_label_en amount currency billing_cycle
    ].freeze
    INDEX_LIMIT = 12
    FEATURED_LIMIT = 3
    NAME_COLUMNS = { "ar" => :name_ar, "en" => :name_en }.freeze

    def initialize(locale:)
      @locale = locale.to_s == "ar" ? "ar" : "en"
    end

    def index(limit: INDEX_LIMIT)
      base.limit(limit)
    end

    def featured(limit: FEATURED_LIMIT)
      base.limit(limit)
    end

    private

    def base
      FeePlan.publicly_visible.select(PUBLIC_COLUMNS).order(
        public_display_order: :asc, NAME_COLUMNS.fetch(@locale) => :asc, id: :asc
      )
    end
  end
end
