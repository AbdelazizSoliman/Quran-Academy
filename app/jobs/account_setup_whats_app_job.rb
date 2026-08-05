class AccountSetupWhatsAppJob < ApplicationJob
  queue_as :notifications

  def perform(invitation:, actor:, encrypted_token:)
    token = Notifications::SecurePayload.decrypt(encrypted_token)
    Notifications::AccountSetupDelivery.new(invitation:, actor:, token:).call
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    Rails.logger.error("WhatsApp account setup job rejected an invalid encrypted token")
  end
end
