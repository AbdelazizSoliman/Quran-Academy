module Notifications
  PhoneResult = Data.define(:valid?, :e164, :provider_address, :error)

  class E164Normalizer
    # Egyptian mobile numbers in local format: 0 + carrier prefix (10/11/12/15) + 8 digits.
    EGYPT_LOCAL_MOBILE = /\A0(1[0125]\d{8})\z/

    def self.call(value)
      raw = value.to_s.strip
      digits = raw.start_with?("00") ? raw.delete_prefix("00").gsub(/\D/, "") : raw.gsub(/\D/, "")
      digits = egyptianize(digits)
      return PhoneResult.new(false, nil, nil, :invalid_phone) unless digits.match?(/\A[1-9]\d{7,14}\z/)

      PhoneResult.new(true, "+#{digits}", digits, nil)
    end

    # Only the recognized Egyptian local mobile shape is rewritten with the country code;
    # any other value starting with "0" is left as-is (and rejected by the general check
    # below) rather than guessing a country code for an ambiguous number.
    def self.egyptianize(digits)
      match = EGYPT_LOCAL_MOBILE.match(digits)
      match ? "20#{match[1]}" : digits
    end
    private_class_method :egyptianize
  end
end
