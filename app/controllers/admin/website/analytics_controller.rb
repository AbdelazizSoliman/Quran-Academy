module Admin
  module Website
    class AnalyticsController < Admin::BaseController
      # rubocop:disable Metrics/AbcSize
      def show
        @days = [7, 30].include?(params[:days].to_i) ? params[:days].to_i : 30
        range = @days.days.ago..Time.current
        @summary = PublicAnalytics::SummaryQuery.new(range:).counts
        @trial_conversion = PublicAnalytics::SummaryQuery.new(range:).trial_conversion
        @contact_conversion = PublicAnalytics::SummaryQuery.new(range:).contact_conversion
        @top_pages = PublicAnalytics::TopPagesQuery.new(range:).call
        @traffic_sources = PublicAnalytics::TrafficSourcesQuery.new(range:).call
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
