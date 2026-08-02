module Notifications
  PhoneResult = Data.define(:valid?, :e164, :provider_address, :error)

  class E164Normalizer
    def self.call(value)
      raw = value.to_s.strip
      digits = raw.start_with?("00") ? raw.delete_prefix("00").gsub(/\D/, "") : raw.gsub(/\D/, "")
      return PhoneResult.new(false, nil, nil, :invalid_phone) unless digits.match?(/\A[1-9]\d{7,14}\z/)

      PhoneResult.new(true, "+#{digits}", digits, nil)
    end
  end
end
