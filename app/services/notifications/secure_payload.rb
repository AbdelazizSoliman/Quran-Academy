module Notifications
  class SecurePayload
    PURPOSE = "notification-delivery-payload-v1".freeze

    def self.encrypt(value) = encryptor.encrypt_and_sign(value, purpose: PURPOSE)
    def self.decrypt(value) = encryptor.decrypt_and_verify(value, purpose: PURPOSE)

    def self.encryptor
      secret = OpenSSL::Digest::SHA256.digest(Rails.application.secret_key_base)
      ActiveSupport::MessageEncryptor.new(secret)
    end
    private_class_method :encryptor
  end
end
