class AccountSetupWhatsAppJob < ApplicationJob
  queue_as :notifications

  def perform(invitation:, actor:, encrypted_token:)
    Rails.logger.info("AccountSetupWhatsAppJob started invitation_id=#{invitation.public_id}")
    token = Notifications::SecurePayload.decrypt(encrypted_token)
    notification = Notifications::AccountSetupDelivery.new(invitation:, actor:, token:).call
    log_finished(invitation, notification)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage => e
    log_invalid_token(invitation, e)
  end

  private

  def log_finished(invitation, notification)
    Rails.logger.info(
      "AccountSetupWhatsAppJob finished invitation_id=#{invitation.public_id} " \
      "notification_status=#{notification&.status.inspect}"
    )
  end

  def log_invalid_token(invitation, exception)
    Rails.logger.error(
      "AccountSetupWhatsAppJob rejected an invalid encrypted token invitation_id=#{invitation.public_id} " \
      "exception=#{exception.class} message=#{exception.message}"
    )
  end
end
