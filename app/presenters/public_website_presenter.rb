class PublicWebsitePresenter
  attr_reader :locale

  def initialize(setting:, academy_setting:, locale:)
    @setting = setting
    @academy_setting = academy_setting
    @locale = locale.to_s.in?(%w[ar en]) ? locale.to_s : "ar"
  end

  def enabled? = setting&.enabled? || false
  def rtl? = locale == "ar"
  def academy_name = localized(:academy_name)
  def hero_title = localized(:hero_title)
  def hero_subtitle = localized(:hero_subtitle)
  def about_text = localized(:about_text)
  def primary_cta_label = localized(:primary_cta_label)

  def primary_cta_url
    configured = setting&.primary_cta_url.presence
    configured.in?([nil, "/account/sign-in"]) ? "/#{locale}/trial" : configured
  end

  def whatsapp_cta_enabled? = setting&.whatsapp_cta_enabled? && whatsapp.present?
  def email = setting&.public_email_enabled? ? academy_setting&.contact_email : nil
  def phone = setting&.public_phone_enabled? ? academy_setting&.contact_phone : nil
  def whatsapp = setting&.public_whatsapp_enabled? ? academy_setting&.whatsapp_number : nil

  def whatsapp_url
    "https://wa.me/#{whatsapp.to_s.gsub(/\D/, '')}" if whatsapp.present?
  end

  def logo_url = academy_setting&.logo_url
  def primary_color = valid_color(academy_setting&.primary_color, "#0B654F")
  def secondary_color = valid_color(academy_setting&.secondary_color, "#A85D09")

  private

  attr_reader :setting, :academy_setting

  def localized(attribute)
    localized_attribute = :"#{attribute}_#{locale}"
    setting&.public_send(localized_attribute).presence || PublicWebsiteSetting.defaults[localized_attribute]
  end

  def valid_color(value, fallback)
    value.to_s.match?(AcademySetting::HEX_COLOR_PATTERN) ? value : fallback
  end
end
