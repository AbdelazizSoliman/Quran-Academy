module StudentGuardianships
  class Operation < ProfileAuditOperation
    FIELDS = %w[
      relationship_type custom_relationship primary_contact emergency_contact legal_guardian
      can_make_academic_decisions receives_academic_updates receives_billing_updates status
      starts_on ends_on notes
    ].freeze

    private

    def audit!(link, actor, event_type, changes = {})
      StudentGuardianshipEvent.create!(
        student_guardianship: link, actor:, event_type:,
        metadata: { "student_public_id" => link.student_profile.public_id,
                    "guardian_public_id" => link.guardian.public_id, "changes" => changes }
      )
    end

    def safe_changes(link)
      audited_changes(link, FIELDS).transform_values.with_index do |value, index|
        audited_changes(link, FIELDS).keys[index] == "notes" ? { "changed" => true } : value
      end
    end
  end
end
