class ApplicationController < ActionController::Base
  include Pagy::Method

  before_action :authenticate_user!, unless: :devise_controller?
  before_action :verify_session_version!, unless: :devise_controller?
  after_action :remember_session_version
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

  def verify_session_version!
    return unless current_user
    return if session[:user_session_version].nil? || session[:user_session_version] == current_user.session_version

    sign_out(current_user)
    redirect_to new_user_session_path, alert: I18n.t("devise.failure.session_invalidated")
  end

  def remember_session_version
    session[:user_session_version] = current_user.session_version if current_user
  end
end
