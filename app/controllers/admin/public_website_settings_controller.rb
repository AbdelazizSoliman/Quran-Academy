module Admin
  class PublicWebsiteSettingsController < BaseController
    before_action :set_public_website_setting

    def edit; end

    def update
      if @public_website_setting.update(public_website_setting_params)
        redirect_to edit_admin_public_website_path, notice: t("admin.public_website.messages.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_public_website_setting
      academy_setting = AcademySetting.current
      @public_website_setting = academy_setting.public_website_setting ||
                                academy_setting.build_public_website_setting(PublicWebsiteSetting.defaults)
    end

    def public_website_setting_params
      params.expect(public_website_setting: %i[
                      enabled academy_name_ar academy_name_en hero_title_ar hero_title_en
                      hero_subtitle_ar hero_subtitle_en about_text_ar about_text_en
                      primary_cta_label_ar primary_cta_label_en primary_cta_url
                      whatsapp_cta_enabled public_email_enabled public_phone_enabled public_whatsapp_enabled
                    ])
    end
  end
end
