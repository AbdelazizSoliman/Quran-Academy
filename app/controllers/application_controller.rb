class ApplicationController < ActionController::Base
  include Pagy::Method

  before_action :authenticate_user!, unless: :devise_controller?
  around_action :use_locale
  around_action :use_time_zone
  layout :application_layout

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def use_locale(&)
    requested_locale = request.query_parameters["locale"] if devise_controller?
    locale = supported_locale(requested_locale) ||
             supported_locale(current_user&.preferred_locale) ||
             I18n.default_locale
    I18n.with_locale(locale, &)
  end

  def use_time_zone(&)
    zone = current_user&.time_zone.presence_in(ActiveSupport::TimeZone.all.map(&:name)) || "Cairo"
    Time.use_zone(zone, &)
  end

  def supported_locale(locale)
    locale&.to_s&.presence_in(I18n.available_locales.map(&:to_s))
  end

  def application_layout
    devise_controller? ? "authentication" : "application"
  end
end
