module Admin
  module Onboarding
    class CreateStudent
      attr_reader :schedule

      PROFILE_KEYS = %i[
        public_id gender date_of_birth nationality country_of_residence city student_type
        learning_status phone_number whatsapp_number preferred_interface_locale preferred_learning_language
        native_language current_quran_level reading_level tajweed_level memorization_level memorized_juz_count
        attendance_percentage learning_goals learning_notes existing_student prior_sessions_taken
        remaining_sessions_at_onboarding
        assigned_teacher_profile_id fee_plan_id weekly_lesson_count lesson_duration_minutes sessions_per_month
        session_type trial_lesson_at
        weekly_price billing_currency schedule_generation_weeks guardian_name guardian_email guardian_phone
        account_delivery_method sibling_student_profile_id
      ].freeze

      # Fields that Madarak's reference form marks optional-with-a-sensible-default (e.g. Quran
      # level, guardian details): if left blank, drop the key entirely so the column's DB default
      # applies, rather than persisting an empty string into a validated/enum-like column.
      OPTIONAL_WITH_DEFAULT_KEYS = %i[gender current_quran_level].freeze

      def initialize(actor:, attributes:)
        @actor = actor
        @attributes = attributes.to_h.symbolize_keys
        OPTIONAL_WITH_DEFAULT_KEYS.each { |key| @attributes.delete(key) if @attributes[key].blank? }
      end

      def call
        profile = nil
        enrollment = nil
        User.transaction do
          user = build_user
          user.save!
          profile = Admin::StudentProfiles::Create.new(actor: @actor, user:, attributes: profile_attributes(user)).call
          raise ActiveRecord::RecordInvalid, profile unless profile.persisted?

          attach_or_create_guardian(profile)
          enrollment = create_enrollment(profile)
          create_lesson_schedule(profile, enrollment)
          # A placeholder email only means the student has no email; it says nothing about whether
          # they're reachable at all. account_delivery_method defaults to "whatsapp" for students,
          # so skipping the invitation here would silently drop the WhatsApp channel too —
          # InvitationChannels/InvitationDelivery already decide per-channel eligibility correctly
          # (email is only attempted when the recipient's own preference actually includes it).
          AccountInvitations::CreateAndSend.new(user:, actor: @actor).call
        end
        profile
      rescue ActiveRecord::RecordInvalid => e
        profile ||= e.record.is_a?(StudentProfile) ? e.record : build_error_profile(e.record)
        profile
      end

      private

      # Madarak treats the student's own email/WhatsApp as optional (the guardian is the primary
      # contact for minors). QA's shared User/Devise model still requires a unique email to
      # authenticate, so an unset email is backed by an internal placeholder rather than blocking
      # account creation. The invitation is still sent (see #call) — InvitationChannels decides
      # per-channel eligibility independently of whether this email is real or a placeholder.
      def build_user
        submitted_email = @attributes[:email].to_s.strip.presence
        first_name, last_name = name_parts
        User.new(
          first_name:, last_name:,
          email: submitted_email || placeholder_email,
          role: :student, status: :pending,
          preferred_locale: @attributes[:preferred_interface_locale].presence || "ar",
          time_zone: effective_time_zone
        ).tap do |user|
          password = SecureRandom.base64(48)
          user.password = user.password_confirmation = password
        end
      end

      # Madarak's on-screen form has a single "اسم الطالب" field; QA's shared User model keeps
      # first/last name for consistency across all roles, so the single name is split on the
      # first space. Arabic compound names (e.g. "عبد الله") won't split perfectly, but the two
      # halves are never shown separately back to the admin (only the joined full name is), so
      # this is a cosmetic imprecision, not a data-loss risk.
      #
      # CSV bulk import (Admin::StudentsCsvImport) still submits the older first_name/last_name
      # columns independently of this form, so that path is honored first when present.
      def name_parts
        return [@attributes[:first_name], @attributes[:last_name]] if @attributes[:first_name].present?

        parts = @attributes[:full_name].to_s.strip.split(/\s+/, 2)
        first = parts[0].presence || "طالب"
        # User#last_name is validated present; a single-word name (common in Arabic) has no
        # second part to use, so fall back to repeating the first word rather than relaxing that
        # shared validation (which every role's account creation relies on).
        [first, parts[1].presence || first]
      end

      PLACEHOLDER_EMAIL_DOMAIN = "no-email.quranacademy.internal".freeze

      def placeholder_email
        "std-#{SecureRandom.hex(8)}@#{PLACEHOLDER_EMAIL_DOMAIN}"
      end

      def effective_time_zone = @attributes[:time_zone].presence || EffectiveTimeZone.for

      def profile_attributes(user)
        slots = schedule_slots
        @attributes.slice(*PROFILE_KEYS).merge(
          display_name: @attributes[:display_name].presence || user.full_name,
          joined_on: Date.current,
          preferred_contact_method: preferred_contact_method,
          guardian_phone: normalized_guardian_phone,
          schedule_slots: slots,
          schedule_weekday: slots.first&.fetch("weekday", nil),
          schedule_time: slots.first&.fetch("time", nil)
        )
      end

      def preferred_contact_method
        return "whatsapp" if @attributes[:whatsapp_number].present? || @attributes[:phone_number].present?
        return "guardian" if normalized_guardian_phone.present?

        "email"
      end

      def normalized_guardian_phone
        digits = @attributes[:guardian_phone].to_s.gsub(/\D/, "")
        return @attributes[:guardian_phone] if digits.blank?

        iso2 = @attributes[:guardian_phone_country_code].to_s.upcase
        dial = StudentProfile::PHONE_COUNTRY_CODES.dig(iso2, 1)
        dial ? "+#{dial}#{digits}" : @attributes[:guardian_phone]
      end

      # Madarak stores the dynamic, unlimited slot list as one JSON-encoded hidden field
      # (name="slots") rather than a fixed number of named params.
      def schedule_slots
        StudentProfile.parse_slots_json(@attributes[:slots_json])
      end

      # Madarak's form has no "existing guardian" picker at all — a guardian is just typed fresh
      # each time. To avoid creating a duplicate Guardian record when a second child of the same
      # family enrolls, an existing guardian with a matching phone number is reused automatically.
      def attach_or_create_guardian(profile)
        return if @attributes[:guardian_name].blank?

        phone = normalized_guardian_phone
        existing = Guardian.where.not(status: "archived").find_by(phone_number: phone) if phone.present?
        return attach_guardian(profile, existing) if existing

        result = Admin::StudentGuardianships::CreateGuardianAndAttach.new(
          actor: @actor, student_profile: profile,
          guardian_attributes: {
            full_name: @attributes[:guardian_name], email: @attributes[:guardian_email],
            phone_number: phone, whatsapp_number: phone,
            preferred_contact_method: phone.present? ? "whatsapp" : "email",
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
          relationship_type: "legal_guardian", primary_contact: true, legal_guardian: true,
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
            preferred_schedule_notes: schedule_note
          }
        ).call
        raise ActiveRecord::RecordInvalid, enrollment unless enrollment.persisted?

        enrollment
      end

      def create_lesson_schedule(profile, enrollment)
        return unless profile.assigned_teacher_profile && complete_schedule_slots.any?
        return if profile.lesson_duration_minutes.blank?

        if enrollment&.persisted?
          create_enrollment_backed_schedule(profile, enrollment)
        elsif profile.fee_plan_id.present?
          create_direct_schedule(profile)
        end
      end

      def create_enrollment_backed_schedule(profile, enrollment)
        starts_on = enrollment.course_offering.planned_start_on || Date.current
        build_schedule!(profile, starts_on, enrollment.course_offering.planned_end_on, enrollment:)
      end

      # Fee-plan-only students have no course offering to anchor the schedule to, so it starts
      # today and runs only as far as the requested generation window (no offering end date cap).
      def create_direct_schedule(profile)
        build_schedule!(profile, Date.current, nil, student_profile: profile)
      end

      def build_schedule!(profile, starts_on, offering_end, enrollment: nil, student_profile: nil)
        attributes = { teacher_profile: profile.assigned_teacher_profile, starts_on:,
                       ends_on: generation_ends_on(starts_on, offering_end),
                       lesson_duration_minutes: profile.lesson_duration_minutes,
                       time_zone: EffectiveTimeZone.for, status: "active" }
        @schedule = EnrollmentLessonSchedules::Create.new(actor: @actor, enrollment:, student_profile:,
                                                          attributes:, slots: complete_schedule_slots).call
        raise ActiveRecord::RecordInvalid, @schedule unless @schedule.persisted?
      end

      # Madarak's "generate for how many weeks" onboarding field controls how far ahead the
      # recurring schedule is generated; a course offering's own end date still wins if it's
      # sooner, so a short course never overruns its planned end.
      def generation_ends_on(starts_on, offering_end)
        weeks = @attributes[:schedule_generation_weeks].presence&.to_i
        return offering_end if weeks.blank? || weeks <= 0

        weeks_end = starts_on + weeks.weeks
        [offering_end, weeks_end].compact.min
      end

      def complete_schedule_slots
        schedule_slots.filter_map do |slot|
          next if slot["weekday"].blank? || slot["time"].blank?

          { weekday: slot.fetch("weekday"), starts_at_local: slot.fetch("time") }
        end
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
