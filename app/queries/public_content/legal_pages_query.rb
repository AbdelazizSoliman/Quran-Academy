module PublicContent
  class LegalPagesQuery
    PUBLIC_COLUMNS = %i[id page_type title_ar title_en body_ar body_en effective_date].freeze

    def find(type)
      base.find_by(page_type: type.to_s)
    end

    def all
      base.order(:page_type)
    end

    def available?(type)
      base.exists?(page_type: type.to_s)
    end

    private

    def base = PublicLegalPage.publicly_visible.select(PUBLIC_COLUMNS)
  end
end
