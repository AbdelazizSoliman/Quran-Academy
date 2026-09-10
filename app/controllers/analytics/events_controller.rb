module Analytics
  class EventsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_session_version!
    protect_from_forgery with: :null_session

    def create
      event = permitted_event
      return head :no_content unless allowed_event?(event)

      PublicAnalytics::Tracker.call(event_type: event[:event_type], request:, session:,
                                    locale: event[:locale], source_path: normalized_source(event),
                                    target: normalized_target(event))
      head :no_content
    rescue StandardError
      head :no_content
    end

    private

    def permitted_event = params.expect(event: %i[event_type locale source_path target])

    def allowed_event?(event)
      %w[trial_cta_click contact_click whatsapp_click
         fee_plan_cta_click].include?(event[:event_type].to_s)
    end

    def normalized_source(event)
      value = event[:source_path].to_s
      return value if value.in?(%w[home fees faq trial contact legal program])

      {
        %r{/(?:ar|en)/fees} => "fees",
        %r{/(?:ar|en)/faq} => "faq",
        %r{/(?:ar|en)/trial} => "trial",
        %r{/(?:ar|en)/contact} => "contact"
      }.find { |pattern, _source| request.path.match?(pattern) }&.last || "home"
    end

    def normalized_target(event) = event[:target].to_s.presence_in(%w[trial contact whatsapp fee_plan])
  end
end
