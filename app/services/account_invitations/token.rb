module AccountInvitations
  module Token
    module_function

    def generate = SecureRandom.urlsafe_base64(32)
    def digest(raw_token) = Digest::SHA256.hexdigest(raw_token.to_s)
  end
end
