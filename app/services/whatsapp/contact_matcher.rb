module Whatsapp
  class ContactMatcher
    CONTACT_FIELDS = {
      StudentProfile => %i[whatsapp_number phone_number guardian_phone],
      Guardian => %i[whatsapp_number phone_number],
      TeacherProfile => %i[whatsapp_number phone_number],
      StaffProfile => %i[whatsapp_number phone_number]
    }.freeze

    def self.call(phone)
      target = Notifications::E164Normalizer.call(phone)
      return unless target.valid?

      matches = []
      CONTACT_FIELDS.each do |model, fields|
        model.find_each do |record|
          matches << record if fields.any? { |field| same_number?(record.public_send(field), target.e164) }
        end
      end
      matches.one? ? matches.first : nil
    end

    def self.same_number?(candidate, target)
      normalized = Notifications::E164Normalizer.call(candidate)
      normalized.valid? && normalized.e164 == target
    end
    private_class_method :same_number?
  end
end
