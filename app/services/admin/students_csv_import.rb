require "csv"

module Admin
  class StudentsCsvImport
    Result = Data.define(:created_count, :errors)

    # Independent of Admin::StudentsController::ONBOARDING_KEYS (the manual create-form's field
    # set, which uses a single "full_name" field to match Madarak's on-screen form) — CSV files
    # are an external data contract, keeping the conventional first_name/last_name/display_name
    # columns. Admin::Onboarding::CreateStudent#name_parts prefers first_name/last_name when
    # present, so both entry points work.
    ALLOWED_KEYS = %w[
      public_id first_name last_name email display_name date_of_birth gender student_type
      learning_status nationality country_of_residence city phone_number whatsapp_number
      preferred_contact_method preferred_interface_locale preferred_learning_language native_language
      current_quran_level reading_level tajweed_level memorization_level memorized_juz_count
      attendance_percentage wallet_balance discount_percentage assigned_teacher_profile_id
      course_offering_id learning_goals sessions_per_month lesson_duration_minutes weekly_lesson_count
      session_type trial_lesson_at weekly_price billing_currency schedule_generation_weeks
      account_delivery_method guardian_name guardian_email guardian_phone sibling_student_profile_id
    ].freeze

    def initialize(actor:, io:)
      @actor = actor
      @io = io
    end

    def call
      created_count = 0
      errors = []

      CSV.new(@io, headers: true, header_converters: ->(header) { header.to_s.strip.downcase }).each.with_index(2) do |row, line|
        attributes = row.to_h.slice(*ALLOWED_KEYS).compact_blank
        profile = Admin::Onboarding::CreateStudent.new(actor: @actor, attributes:).call
        if profile.persisted? && profile.errors.empty?
          created_count += 1
        else
          errors << { line:, messages: profile.errors.full_messages }
        end
      rescue CSV::MalformedCSVError => e
        errors << { line:, messages: [e.message] }
      end

      Result.new(created_count:, errors:)
    end
  end
end
