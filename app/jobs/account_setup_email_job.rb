class AccountSetupEmailJob < ApplicationJob
  queue_as :notifications

  def perform(invitation:, actor:, encrypted_token:)
    token = Notifications::SecurePayload.decrypt(encrypted_token)
    delivered = Notifications::InvitationEmailDelivery.new(invitation:, token:, actor:).call
    AccountInvitations::MarkSent.call(invitation:, actor:) if delivered
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    Rails.logger.error("Account setup email job rejected an invalid encrypted token")
  end
end
