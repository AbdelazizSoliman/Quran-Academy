module Notifications
  Recipient = Data.define(:valid?, :user, :guardian, :address, :provider_address, :masked_address, :locale, :error)

  class RecipientResolver
    def initialize(user:, channel:, primary_guardian: false, guardian: nil)
      @user = user
      @channel = channel.to_s
      @primary_guardian = ActiveModel::Type::Boolean.new.cast(primary_guardian)
      @guardian = guardian
    end

    def call
      return invalid(:invalid_channel) unless @channel.in?(Notification::CHANNELS)
      return guardian_recipient if @primary_guardian
      return email_recipient if @channel == "email"

      whatsapp_recipient
    end

    private

    # A student's own WhatsApp/phone is tried first; if neither is set (Madarak onboarding
    # allows leaving both blank, treating the guardian as the primary contact — see
    # Admin::Onboarding::CreateStudent#build_user), this falls back to the primary guardian's
    # number automatically. Unlike #guardian_recipient below, this applies to every student
    # regardless of minor?, and doesn't require the caller to opt in with primary_guardian: true.
    def whatsapp_recipient
      primary = phone_recipient(profile_phone, @user.preferred_locale)
      return primary if primary.valid?

      student_guardian_fallback || primary
    end

    def student_guardian_fallback
      profile = @user.student_profile
      return nil unless profile

      guardian = profile.student_guardianships.active.find_by(primary_contact: true)&.guardian
      return nil unless guardian

      number = guardian.whatsapp_number.presence || guardian.phone_number
      return nil if number.blank?

      phone_recipient(number, guardian.preferred_language, guardian:)
    end

    def guardian_recipient
      profile = @user.student_profile
      return invalid(:guardian_not_available) unless @channel == "whatsapp" && profile&.minor?

      guardianship = profile.student_guardianships.active.find_by(primary_contact: true)
      guardian = @guardian || guardianship&.guardian
      return invalid(:guardian_not_available) if @guardian && guardianship&.guardian_id != @guardian.id
      return invalid(:guardian_not_available) unless guardian

      phone_recipient(guardian.whatsapp_number.presence || guardian.phone_number,
                      guardian.preferred_language, guardian:)
    end

    def email_recipient
      address = @user.email.to_s.strip.downcase
      return invalid(:invalid_email) unless address.match?(URI::MailTo::EMAIL_REGEXP)

      Recipient.new(true, @user, nil, address, address, mask_email(address), locale(@user.preferred_locale), nil)
    end

    def phone_recipient(value, preferred_locale, guardian: nil)
      phone = E164Normalizer.call(value)
      return invalid(phone.error) unless phone.valid?

      Recipient.new(true, @user, guardian, phone.e164, phone.provider_address, mask_phone(phone.e164),
                    locale(preferred_locale), nil)
    end

    def profile_phone
      profile = @user.teacher_profile || @user.student_profile || @user.staff_profile
      profile&.whatsapp_number.presence || profile&.phone_number
    end

    def locale(value) = value.to_s.presence_in(%w[ar en]) || AcademySetting.current.default_locale
    def mask_phone(value) = "#{'*' * [value.length - 4, 0].max}#{value.last(4)}"

    def mask_email(value)
      local, domain = value.split("@", 2)
      "#{local.first}***@#{domain}"
    end

    def invalid(error)
      Recipient.new(false, @user, nil, nil, nil, "unavailable", locale(@user.preferred_locale), error)
    end
  end
end
