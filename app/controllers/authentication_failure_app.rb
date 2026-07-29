# frozen_string_literal: true

class AuthenticationFailureApp < Devise::FailureApp
  def recall
    flash[:alert] = i18n_message(:invalid) if is_flashing_format?
    redirect_to Rails.application.routes.url_helpers.new_user_session_path(locale: i18n_locale),
                status: Devise.responder.redirect_status
  end
end
