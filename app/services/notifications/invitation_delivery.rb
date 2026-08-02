module Notifications
  class InvitationDelivery
    MODES = {
      "email_only" => %w[email],
      "whatsapp_only" => %w[whatsapp],
      "email_and_whatsapp" => %w[email whatsapp]
    }.freeze

    def initialize(invitation:, token:, actor:)
      @invitation = invitation
      @token = token
      @actor = actor
    end

    def call
      channels.map { |channel| deliver(channel) }.any?
    end

    private

    def channels = MODES.fetch(AcademySetting.current.invitation_delivery_mode)

    def deliver(channel)
      if channel == "email"
        return InvitationEmailDelivery.new(invitation: @invitation, token: @token, actor: @actor).call
      end

      notification = Dispatch.new(actor: @actor, recipient: @invitation.user, source: @invitation,
                                  type: "account_invitation", channel:, invitation_token: @token,
                                  persist_recipient_failure: true).call
      notification.sent? || notification.delivered?
    rescue StandardError => e
      Rails.logger.error("Invitation #{channel} delivery failed (#{e.class}): #{e.message}")
      false
    end
  end
end
