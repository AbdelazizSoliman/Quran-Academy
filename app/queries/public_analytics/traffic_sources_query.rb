module PublicAnalytics
  class TrafficSourcesQuery
    def initialize(range:, limit: 10)
      @range = range
      @limit = limit
    end

    def call
      PublicAnalyticsEvent.within(@range).where.not(utm_source: [nil, ""])
                          .group(:utm_source, :utm_campaign).order(Arel.sql("COUNT(*) DESC")).limit(@limit)
                          .pluck(:utm_source, :utm_campaign,
                                 Arel.sql("SUM(CASE WHEN event_type = 'page_view' THEN 1 ELSE 0 END)"),
                                 Arel.sql("SUM(CASE WHEN event_type = 'trial_submitted' THEN 1 ELSE 0 END)"),
                                 Arel.sql("SUM(CASE WHEN event_type = 'contact_submitted' THEN 1 ELSE 0 END)"))
    end
  end
end
