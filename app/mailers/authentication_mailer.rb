class AuthenticationMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers

  default template_path: "devise/mailer"

  def reset_password_instructions(record, token, options = {})
    I18n.with_locale(record.preferred_locale.presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale) do
      super
    end
  end
end
