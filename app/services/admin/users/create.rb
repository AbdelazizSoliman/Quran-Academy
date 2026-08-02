module Admin
  module Users
    class Create < Operation
      def initialize(actor:, attributes:)
        super(actor:)
        @attributes = attributes
      end

      def call
        user = build_user
        return user unless normalize_contact(user)

        User.transaction do
          user.save!
          create_profile!(user)
          audit!(user, "created", change_metadata(user.previous_changes.slice(*SAFE_FIELDS)))
          AccountInvitations::CreateAndSend.new(user:, actor: @actor).call
        end
        user
      rescue ActiveRecord::RecordInvalid => e
        merge_profile_errors(user, e.record) unless e.record == user
        user
      end

      private

      def build_user
        user = User.new(@attributes.except(:phone_number, :whatsapp_number))
        user.status = :pending
        user.preferred_locale = nil if @attributes[:preferred_locale].blank?
        password = SecureRandom.base64(48)
        user.password = user.password_confirmation = password
        user
      end

      def normalize_contact(user)
        phone = normalize_phone(user, :phone_number, @attributes[:phone_number])
        return false unless phone

        whatsapp_value = @attributes[:whatsapp_number].presence || phone.e164
        whatsapp = normalize_phone(user, :whatsapp_number, whatsapp_value)
        return false unless whatsapp

        @contact = { phone_number: phone.e164, whatsapp_number: whatsapp.e164 }
        true
      end

      def normalize_phone(user, attribute, value)
        if value.blank?
          user.errors.add(:base, I18n.t("admin.users.errors.#{attribute}_blank"))
          return
        end

        result = Notifications::E164Normalizer.call(value)
        user.errors.add(:base, I18n.t("admin.users.errors.#{attribute}_invalid")) unless result.valid?
        result if result.valid?
      end

      def create_profile!(user)
        profile = case user.role
                  when "teacher" then create_teacher_profile(user)
                  when "student" then create_student_profile(user)
                  else create_staff_profile(user)
                  end
        raise ActiveRecord::RecordInvalid, profile if profile.errors.any?
      end

      def create_teacher_profile(user)
        Admin::TeacherProfiles::Create.new(
          actor: @actor, user:,
          attributes: @contact.merge(display_name: user.full_name, joined_on: Date.current)
        ).call
      end

      def create_student_profile(user)
        Admin::StudentProfiles::Create.new(
          actor: @actor, user:,
          attributes: @contact.merge(display_name: user.full_name, joined_on: Date.current,
                                     preferred_contact_method: "whatsapp")
        ).call
      end

      def create_staff_profile(user)
        user.create_staff_profile!(@contact.merge(display_name: user.full_name,
                                                  created_by: @actor, updated_by: @actor))
      end

      def merge_profile_errors(user, profile)
        profile.errors.full_messages.each { |message| user.errors.add(:base, message) }
      end
    end
  end
end
