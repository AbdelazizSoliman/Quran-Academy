module TeacherProfiles
  class Operation
    ADMIN_FIELDS = %w[
      display_name bio gender date_of_birth nationality country_of_residence city phone_number
      whatsapp_number emergency_contact_name emergency_contact_phone highest_qualification
      qualification_details years_of_teaching_experience quran_teaching_experience_years
      tajweed_qualification ijazah_status ijazah_details teaching_languages student_age_groups
      teaching_specializations employment_status engagement_type joined_on left_on
      default_lesson_rate compensation_currency compensation_unit internal_notes notification_method
      message_language workload_percentage on_leave work_days work_start_time work_end_time
      monthly_salary mid_period_previous_dues
    ].freeze
    SELF_FIELDS = %w[
      display_name bio gender date_of_birth nationality country_of_residence city phone_number
      whatsapp_number emergency_contact_name emergency_contact_phone highest_qualification
      qualification_details years_of_teaching_experience quran_teaching_experience_years
      tajweed_qualification ijazah_status ijazah_details teaching_languages student_age_groups
      teaching_specializations
    ].freeze
    COMPENSATION_FIELDS = %w[default_lesson_rate compensation_currency compensation_unit].freeze

    private

    def audited_changes(profile, fields)
      profile.changes.slice(*fields).transform_values do |before, after|
        { "from" => serialized(before), "to" => serialized(after) }
      end
    end

    def serialized(value)
      value.is_a?(BigDecimal) ? value.to_s("F") : value
    end

    def audit!(profile, actor, event_type, changes = {})
      TeacherProfileEvent.create!(
        teacher_profile: profile, actor:, event_type:, metadata: { "changes" => changes }
      )
    end
  end
end
