module ManualCommunications
  PhoneResult = Data.define(:valid?, :digits, :error)

  class PhoneNormalizer
    def self.call(number)
      digits = number.to_s.gsub(/\D/, "")
      return PhoneResult.new(false, nil, :invalid_phone) unless digits.length.between?(8, 15)

      PhoneResult.new(true, digits, nil)
    end
  end
end
