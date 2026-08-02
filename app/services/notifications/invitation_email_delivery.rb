module Notifications
  class InvitationEmailDelivery
    def initialize(invitation:, token:, actor:)
      @invitation = invitation
      @token = token
      @actor = actor
    end

    def call
      setting = AcademySetting.current
      return false unless setting.email_notifications_enabled? && setting.invitation_notifications_enabled?

      mailer = AccountInvitationMailer.with(invitation: @invitation, token: @token).invitation_email
      subject = I18n.t("invitations.mailer.subject", locale: @invitation.user.preferred_locale,
                                                    academy: AcademySetting.current.academy_name)
      notification = Notification.create!(recipient_user: @invitation.user, actor: @actor, source: @invitation,
                                          channel: "email", notification_type: "account_invitation",
                                          provider: "resend",
                                          recipient_address_masked: mask_email(@invitation.user.email),
                                          recipient_locale: @invitation.user.preferred_locale,
                                          subject:,
                                          message_snapshot: I18n.t("notifications.secure_link_omitted"))
      notification.events.create!(actor: @actor, event_type: "created", after_data: { "status" => "pending" })
      Attempt.new(notification:, actor: @actor, recipient_address: @invitation.user.email,
                  delivery_body: "secure invitation", provider_options: { mailer: }).call.sent?
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Invitation notification logging failed (#{e.class})")
      false
    end

    private

    def mask_email(value)
      local, domain = value.split("@", 2)
      "#{local.first}***@#{domain}"
    end
  end
end
