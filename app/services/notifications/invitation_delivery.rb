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
      mode = AcademySetting.current.invitation_delivery_mode
      Rails.logger.info("InvitationDelivery started invitation_id=#{@invitation.public_id}")
      Rails.logger.info("InvitationDelivery mode=#{mode}")
      MODES.fetch(mode).map { |channel| deliver(channel) }.any?
    end

    private

    def deliver(channel)
      if channel == "email"
        Rails.logger.info("InvitationDelivery email dispatch started invitation_id=#{@invitation.public_id}")
        success = InvitationEmailDelivery.new(invitation: @invitation, token: @token, actor: @actor).call
        Rails.logger.info("InvitationDelivery email dispatch finished success=#{success}")
        return success
      end

      Rails.logger.info("InvitationDelivery WhatsApp dispatch started invitation_id=#{@invitation.public_id}")
      notification = Dispatch.new(actor: @actor, recipient: @invitation.user, source: @invitation,
                                  type: "account_invitation", channel:, invitation_token: @token,
                                  persist_recipient_failure: true).call
      success = notification.sent? || notification.delivered?
      Rails.logger.info("InvitationDelivery WhatsApp dispatch finished success=#{success} status=#{notification.status}")
      success
    rescue StandardError => e
      Rails.logger.error("Invitation #{channel} delivery failed (#{e.class}): #{e.message}")
      Rails.logger.info("InvitationDelivery #{channel} dispatch finished success=false")
      false
    end
  end
end
