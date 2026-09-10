module PublicAnalytics
  class SummaryQuery
    EVENT_LABELS = %w[page_view trial_cta_click trial_submitted contact_click contact_submitted whatsapp_click
                      fee_plan_cta_click].freeze

    def initialize(range: 30.days.ago..Time.current)
      @events = PublicAnalyticsEvent.within(range)
    end

    def counts = EVENT_LABELS.index_with { |event| @events.where(event_type: event).count }

    def trial_conversion = ratio(counts.fetch("trial_submitted"), counts.fetch("trial_cta_click"))
    def contact_conversion = ratio(counts.fetch("contact_submitted"), counts.fetch("contact_click"))

    private

    def ratio(numerator, denominator) = denominator.zero? ? nil : (numerator.to_f / denominator * 100).round(1)
  end
end
