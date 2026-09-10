module PublicAnalytics
  class TopPagesQuery
    def initialize(range:, limit: 10)
      @range = range
      @limit = limit
    end

    def call
      PublicAnalyticsEvent.within(@range).where(event_type: "page_view").group(:path)
                          .order(Arel.sql("COUNT(*) DESC")).limit(@limit).count
    end
  end
end
