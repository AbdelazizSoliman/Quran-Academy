module Notifications
  class InvitationDelivery
    def initialize(invitation:, token:, actor:)
      @invitation = invitation
      @token = token
      @actor = actor
    end

    def call
      Rails.logger.info("InvitationDelivery started invitation_id=#{@invitation.public_id}")
      email_succeeded = deliver_email
      enqueue_whatsapp
      email_succeeded
    end

    private

    def deliver_email
      Rails.logger.info("InvitationDelivery email dispatch started invitation_id=#{@invitation.public_id}")
      success = InvitationEmailDelivery.new(invitation: @invitation, token: @token, actor: @actor).call
      Rails.logger.info("InvitationDelivery email dispatch finished success=#{success}")
      success
    rescue StandardError => e
      Rails.logger.error("Invitation email delivery failed (#{e.class})")
      Rails.logger.info("InvitationDelivery email dispatch finished success=false")
      false
    end

    def enqueue_whatsapp
      return unless AcademySetting.current.invitation_delivery_mode.in?(%w[whatsapp_only email_and_whatsapp])
      return unless ActiveModel::Type::Boolean.new.cast(ENV.fetch("WHATSAPP_ENABLED", "false"))
      return unless whatsapp_configuration_present?

      encrypted_token = SecurePayload.encrypt(@token)
      ActiveRecord.after_all_transactions_commit { enqueue_job(encrypted_token) }
    rescue StandardError => e
      Rails.logger.error("WhatsApp invitation preparation failed (#{e.class})")
    end

    def enqueue_job(encrypted_token)
      AccountSetupWhatsAppJob.perform_later(invitation: @invitation, actor: @actor, encrypted_token:)
    rescue StandardError => e
      Rails.logger.error("WhatsApp invitation enqueue failed (#{e.class})")
    end

    def whatsapp_configuration_present?
      %w[WHATSAPP_ACCESS_TOKEN WHATSAPP_PHONE_NUMBER_ID WHATSAPP_BUSINESS_ACCOUNT_ID
         WHATSAPP_GRAPH_API_VERSION WHATSAPP_ACCOUNT_SETUP_TEMPLATE
         WHATSAPP_ACCOUNT_SETUP_LANGUAGE WHATSAPP_ACCOUNT_SETUP_URL_PREFIX].all? { |key| ENV[key].present? }
    end
  end
end
