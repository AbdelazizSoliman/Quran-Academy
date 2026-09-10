module PublicContent
  class FaqsQuery
    PUBLIC_COLUMNS = %i[id question_ar question_en answer_ar answer_en public_display_order].freeze
    INDEX_LIMIT = 100
    HOME_LIMIT = 5

    def available? = PublicFaq.publicly_visible.exists?
    def index = base.limit(INDEX_LIMIT)
    def homepage = base.limit(HOME_LIMIT)

    private

    def base = PublicFaq.publicly_visible.public_ordered.select(PUBLIC_COLUMNS)
  end
end
