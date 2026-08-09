module AccountInvitations
  class UrlBuilder
    def self.call(token:, locale:, url_options: Rails.application.config.action_mailer.default_url_options)
      Rails.application.routes.url_helpers.edit_account_invitation_url(
        token:, locale:, **url_options
      )
    end
  end
end
