module Admin
  module Onboarding
    class CreateStudent
      PROFILE_KEYS = %i[
        display_name gender date_of_birth nationality country_of_residence city student_type learning_status
        phone_number whatsapp_number preferred_contact_method preferred_interface_locale preferred_learning_language
        native_language current_quran_level reading_level tajweed_level memorization_level memorized_juz_count
        learning_goals learning_notes wallet_balance discount_percentage assigned_teacher_profile_id package_name
        weekly_lesson_count lesson_duration_minutes sessions_per_month session_type trial_lesson_at
        weekly_price billing_currency guardian_name guardian_email guardian_phone account_delivery_method
        sibling_student_profile_id
      ].freeze

      SCHEDULE_POSITIONS = 1..3

      def initialize(actor:, attributes:)
        @actor = actor
        @attributes = attributes.to_h.symbolize_keys
      end

      def call
        profile = nil
        User.transaction do
          user = build_user
          user.save!
          profile = Admin::StudentProfiles::Create.new(actor: @actor, user:, attributes: profile_attributes(user)).call
          raise ActiveRecord::RecordInvalid, profile unless profile.persisted?

          attach_or_create_guardian(profile)
          create_enrollment(profile)
          AccountInvitations::CreateAndSend.new(user:, actor: @actor).call
        end
        profile
      rescue ActiveRecord::RecordInvalid => e
        profile ||= e.record.is_a?(StudentProfile) ? e.record : build_error_profile(e.record)
        profile
      end

      private

      def build_user
        User.new(
          first_name: @attributes[:first_name], last_name: @attributes[:last_name],
          email: @attributes[:email], role: :student, status: :pending,
          preferred_locale: @attributes[:preferred_interface_locale].presence || "ar", time_zone: "Cairo"
        ).tap do |user|
          password = SecureRandom.base64(48)
          user.password = user.password_confirmation = password
        end
      end

      def profile_attributes(user)
        slots = schedule_slots
        @attributes.slice(*PROFILE_KEYS).merge(
          display_name: @attributes[:display_name].presence || user.full_name,
          joined_on: Date.current,
          schedule_slots: slots,
          schedule_weekday: slots.first&.fetch("weekday", nil),
          schedule_time: slots.first&.fetch("time", nil)
        )
      end

      def schedule_slots
        SCHEDULE_POSITIONS.filter_map do |position|
          weekday = @attributes[:"schedule_weekday_#{position}"].to_s.downcase.presence
          time = @attributes[:"schedule_time_#{position}"].to_s.presence
          next if weekday.blank? && time.blank?

          { "weekday" => weekday, "time" => time }
        end
      end

      def attach_or_create_guardian(profile)
        guardian = Guardian.find_by(id: @attributes[:existing_guardian_id])
        return attach_guardian(profile, guardian) if guardian
        return if @attributes[:guardian_name].blank?

        result = Admin::StudentGuardianships::CreateGuardianAndAttach.new(
          actor: @actor, student_profile: profile,
          guardian_attributes: {
            full_name: @attributes[:guardian_name], email: @attributes[:guardian_email],
            phone_number: @attributes[:guardian_phone], whatsapp_number: @attributes[:guardian_phone],
            preferred_contact_method: @attributes[:guardian_phone].present? ? "whatsapp" : "email",
            preferred_language: @attributes[:preferred_interface_locale].presence || "ar", status: "active"
          },
          relationship_attributes: guardianship_attributes
        ).call
        raise ActiveRecord::RecordInvalid, result.guardian unless result.success?
      end

      def attach_guardian(profile, guardian)
        relationship = Admin::StudentGuardianships::Create.new(
          actor: @actor, student_profile: profile, guardian:,
          attributes: guardianship_attributes
        ).call
        raise ActiveRecord::RecordInvalid, relationship unless relationship.persisted?
      end

      def guardianship_attributes
        {
          relationship_type: "parent", primary_contact: true, legal_guardian: true,
          emergency_contact: true, receives_academic_updates: true, receives_billing_updates: true,
          status: "active", starts_on: Date.current
        }
      end

      def create_enrollment(profile)
        offering = CourseOffering.find_by(id: @attributes[:course_offering_id])
        return unless offering

        enrollment = Admin::Enrollments::Create.new(
          actor: @actor, student_profile: profile, course_offering: offering,
          attributes: {
            application_source: "administrator",
            preferred_schedule_notes: schedule_note,
            administrator_notes: @attributes[:package_name]
          }
        ).call
        raise ActiveRecord::RecordInvalid, enrollment unless enrollment.persisted?
      end

      def schedule_note
        schedule_slots.map { |slot| "#{slot['weekday']} #{slot['time']}" }.join("، ")
      end

      def build_error_profile(record)
        profile = StudentProfile.new(profile_attributes(record.is_a?(User) ? record : User.new))
        record.errors.full_messages.each { |message| profile.errors.add(:base, message) }
        profile
      end
    end
  end
end
