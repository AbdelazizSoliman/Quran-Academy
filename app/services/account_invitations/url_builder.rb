module AccountInvitations
  class UrlBuilder
    def self.call(token:, locale:)
      Rails.application.routes.url_helpers.edit_account_invitation_url(
        token:, locale:, **Rails.application.config.action_mailer.default_url_options
      )
    end
  end
end
