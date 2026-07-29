class UiController < ApplicationController
  skip_before_action :authenticate_user!
  around_action :use_requested_locale

  def index; end

  private

  def use_requested_locale(&)
    requested_locale = params.permit(:locale)[:locale]
    locale = requested_locale.presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
    I18n.with_locale(locale, &)
  end
end
