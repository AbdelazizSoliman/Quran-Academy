module Public
  class BaseController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_session_version!
    layout "public"
    before_action :load_public_site
    before_action :require_public_website!

    private

    def public_locale_selection? = true

    def load_public_site
      setting = PublicWebsiteSetting.includes(:academy_setting).first
      @public_site = PublicWebsitePresenter.new(
        setting:, academy_setting: setting&.academy_setting, locale: I18n.locale
      )
      @public_programs_available = PublicCatalog::ProgramsQuery.new(locale: public_locale).available?
      @public_faqs_available = PublicContent::FaqsQuery.new.available?
    end

    # Every public page follows the same controlled unavailable behaviour as the Phase 1 homepage.
    def require_public_website!
      return if @public_site.enabled?

      render "public/home/unavailable", status: :service_unavailable
    end

    def public_locale = @public_site.locale
    def public_programs_available? = @public_programs_available
    def public_programs_admin? = current_user&.active? && current_user.admin?
    def public_faqs_available? = @public_faqs_available
    def public_faqs_admin? = current_user&.active? && current_user.admin?

    helper_method :public_locale, :public_programs_available?, :public_programs_admin?,
                  :public_faqs_available?, :public_faqs_admin?
  end
end
