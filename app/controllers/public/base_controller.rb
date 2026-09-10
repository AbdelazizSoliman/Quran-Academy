module Public
  class BaseController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_session_version!
    layout "public"
    before_action :load_public_site
    before_action :require_public_website!
    before_action :capture_public_analytics_utm
    after_action :track_public_page_view

    private

    def public_locale_selection? = true

    def load_public_site
      setting = PublicWebsiteSetting.includes(:academy_setting).first
      @public_site = PublicWebsitePresenter.new(
        setting:, academy_setting: setting&.academy_setting, locale: I18n.locale
      )
      @public_programs_available = PublicCatalog::ProgramsQuery.new(locale: public_locale).available?
      @public_faqs_available = PublicContent::FaqsQuery.new.available?
      @public_legal_pages_available = PublicLegalPage::PAGE_TYPES.index_with do |type|
        PublicContent::LegalPagesQuery.new.available?(type)
      end
    end

    # Every public page follows the same controlled unavailable behaviour as the Phase 1 homepage.
    def require_public_website!
      return if @public_site.enabled?

      render "public/home/unavailable", status: :service_unavailable
    end

    def capture_public_analytics_utm
      PublicAnalytics::Tracker.capture_utm!(request:, session:)
    end

    def track_public_page_view
      return unless request.get? && response.successful? && response.media_type == "text/html"

      PublicAnalytics::Tracker.call(event_type: "page_view", request:, session:,
                                    locale: public_locale, source_path: analytics_source_path)
    end

    def analytics_source_path
      {
        "home" => "home", "fees" => "fees", "faqs" => "faq",
        "trial_requests" => "trial", "contact_requests" => "contact",
        "legal_pages" => "legal", "programs" => "program"
      }.fetch(controller_name, controller_name)
    end

    def public_locale = @public_site.locale
    def public_programs_available? = @public_programs_available
    def public_programs_admin? = current_user&.active? && current_user.admin?
    def public_faqs_available? = @public_faqs_available
    def public_faqs_admin? = current_user&.active? && current_user.admin?
    def public_legal_page_available?(type) = @public_legal_pages_available[type.to_s]

    helper_method :public_locale, :public_programs_available?, :public_programs_admin?,
                  :public_faqs_available?, :public_faqs_admin?
    helper_method :public_legal_page_available?
  end
end
