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

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || dashboard_path
  end

  def require_release_feature!(feature)
    head :not_found unless ReleaseFeatures.enabled?(feature)
  end

  helper_method :release_feature_enabled?, :academy_setting

  def release_feature_enabled?(feature)
    ReleaseFeatures.enabled?(feature)
  end

  def use_locale(&)
    requested_locale = params[:locale] if public_locale_selection?
    locale = supported_locale(requested_locale) ||
             supported_locale(current_user&.preferred_locale) ||
             supported_locale(academy_setting&.default_locale) ||
             I18n.default_locale
    I18n.with_locale(locale, &)
  end

  def public_locale_selection?
    devise_controller? || controller_name == "account_invitations"
  end

  def use_time_zone(&)
    Time.use_zone(EffectiveTimeZone.for(current_user), &)
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

  def academy_setting
    return @academy_setting if defined?(@academy_setting)

    @academy_setting = AcademySetting.current_or_nil
  end
end
