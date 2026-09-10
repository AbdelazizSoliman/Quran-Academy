module PublicAnalytics
  class Tracker
    UTM_KEYS = %w[utm_source utm_medium utm_campaign utm_term utm_content].freeze
    MAX_VALUE_LENGTH = 255

    # rubocop:disable Metrics/ParameterLists
    def self.call(event_type:, request:, session:, locale:, source_path: nil, target: nil,
                  inquiry_type: nil, public_inquiry: nil, fee_plan: nil)
      return unless PublicAnalyticsEvent::EVENT_TYPES.include?(event_type.to_s)

      new(event_type:, request:, session:, locale:, source_path:, target:, inquiry_type:,
          public_inquiry:, fee_plan:).call
    rescue StandardError => e
      Rails.logger.warn("Public analytics tracking failed exception=#{e.class}")
      nil
    end

    def initialize(event_type:, request:, session:, locale:, source_path:, target:, inquiry_type:, public_inquiry:,
                   fee_plan:)
      @event_type = event_type.to_s
      @request = request
      @session = session
      @locale = locale.to_s.in?(PublicAnalyticsEvent::LOCALES) ? locale.to_s : "en"
      @source_path = source_path
      @target = target
      @inquiry_type = inquiry_type
      @public_inquiry = public_inquiry
      @fee_plan = fee_plan
    end
    # rubocop:enable Metrics/ParameterLists

    def call
      PublicAnalyticsEvent.create!(attributes)
    end

    def capture_utm!
      values = UTM_KEYS.index_with { |key| sanitize(@request.params[key]) }.compact_blank
      @session[:public_analytics_utm] = values if values.any?
      values
    end

    def self.capture_utm!(request:, session:)
      new(event_type: "page_view", request:, session:, locale: "en", source_path: nil,
          target: nil, inquiry_type: nil, public_inquiry: nil, fee_plan: nil).capture_utm!
    rescue StandardError
      {}
    end

    private

    def attributes
      {
        event_type: @event_type, occurred_at: Time.current, locale: @locale,
        path: sanitize(@request.path).presence || "/", source_path: sanitize(@source_path),
        target: sanitize(@target), inquiry_type: @inquiry_type,
        public_inquiry: @public_inquiry, fee_plan: @fee_plan,
        visitor_token: visitor_token, referrer: sanitize(@request.referer),
        **utm_values
      }
    end

    def visitor_token
      @session[:public_analytics_visitor_token] ||= SecureRandom.hex(16)
    end

    def utm_values
      stored = @session[:public_analytics_utm].to_h
      UTM_KEYS.index_with { |key| sanitize(@request.params[key].presence || stored[key]) }.compact_blank
    end

    def sanitize(value) = value.to_s.strip.presence&.truncate(MAX_VALUE_LENGTH)
  end
end
