module Admin
  module Onboarding
    class CreateTeacher
      PROFILE_KEYS = %i[
        display_name phone_number whatsapp_number notification_method message_language employment_status
        workload_percentage on_leave work_days work_start_time work_end_time compensation_unit default_lesson_rate
        monthly_salary compensation_currency mid_period_previous_dues engagement_type joined_on teaching_languages
        student_age_groups teaching_specializations
      ].freeze

      def initialize(actor:, attributes:)
        @actor = actor
        @attributes = attributes.to_h.symbolize_keys
      end

      def call
        profile = nil
        User.transaction do
          user = build_user
          user.save!
          profile = Admin::TeacherProfiles::Create.new(actor: @actor, user:, attributes: profile_attributes(user)).call
          raise ActiveRecord::RecordInvalid, profile unless profile.persisted?
          create_availabilities(profile) if profile.employment_status == "active"
          AccountInvitations::CreateAndSend.new(user:, actor: @actor).call
        end
        profile
      rescue ActiveRecord::RecordInvalid => e
        profile ||= e.record.is_a?(TeacherProfile) ? e.record : build_error_profile(e.record)
        profile
      end

      private

      def build_user
        user = User.new(first_name: @attributes[:first_name], last_name: @attributes[:last_name],
                        email: @attributes[:email], role: :teacher, status: :pending,
                        preferred_locale: @attributes[:message_language].presence || "ar", time_zone: "Cairo")
        password = SecureRandom.base64(48)
        user.password = user.password_confirmation = password
        user
      end

      def profile_attributes(user)
        @attributes.slice(*PROFILE_KEYS).merge(display_name: @attributes[:display_name].presence || user.full_name,
                                              joined_on: @attributes[:joined_on].presence || Date.current)
      end

      def create_availabilities(profile)
        return if @attributes[:work_start_time].blank? || @attributes[:work_end_time].blank?

        Array(@attributes[:work_days]).compact_blank.each do |day|
          availability = Admin::TeacherAvailabilities::Create.new(
            actor: @actor, teacher_profile: profile,
            attributes: { weekday: day, starts_at_local: @attributes[:work_start_time],
                          ends_at_local: @attributes[:work_end_time], availability_type: "general",
                          status: "active", effective_from: Date.current, time_zone: "Cairo" }
          ).call
          raise ActiveRecord::RecordInvalid, availability unless availability.persisted?
        end
      end

      def build_error_profile(record)
        profile = TeacherProfile.new(profile_attributes(record.is_a?(User) ? record : User.new))
        record.errors.full_messages.each { |message| profile.errors.add(:base, message) }
        profile
      end
    end
  end
end
