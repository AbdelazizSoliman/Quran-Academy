module Public
  class HomeController < BaseController
    def show
      setting = PublicWebsiteSetting.includes(:academy_setting).first
      @public_site = PublicWebsitePresenter.new(
        setting:, academy_setting: setting&.academy_setting, locale: I18n.locale
      )

      render :unavailable, status: :service_unavailable unless @public_site.enabled?
    end
  end
end
