module StudentProfiles
  class Operation < ProfileAuditOperation
    ADMIN_FIELDS = %w[
      display_name gender date_of_birth nationality country_of_residence city phone_number
      whatsapp_number preferred_contact_method preferred_interface_locale preferred_learning_language
      native_language current_quran_level reading_level tajweed_level memorization_level
      memorized_surahs memorized_juz_count learning_goals learning_notes special_learning_needs
      medical_notes safeguarding_notes emergency_contact_name emergency_contact_phone student_type
      learning_status joined_on left_on internal_notes
    ].freeze
    SELF_FIELDS = %w[
      display_name phone_number whatsapp_number country_of_residence city
      preferred_learning_language native_language learning_goals
    ].freeze

    private

    def audit!(profile, actor, event_type, changes = {})
      StudentProfileEvent.create!(student_profile: profile, actor:, event_type:, metadata: { "changes" => changes })
    end

    def safe_changes(profile, fields)
      changes = audited_changes(profile, fields)
      changes.transform_values.with_index do |value, index|
        fields_for_changes = profile.changes.slice(*fields).keys
        StudentProfile::SENSITIVE_FIELDS.include?(fields_for_changes[index]) ? { "changed" => true } : value
      end
    end
  end
end
