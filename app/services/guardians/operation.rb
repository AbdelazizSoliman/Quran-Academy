module Guardians
  class Operation < ProfileAuditOperation
    FIELDS = %w[
      full_name gender email phone_number whatsapp_number preferred_contact_method
      preferred_language country city occupation internal_notes
    ].freeze

    private

    def audit!(guardian, actor, event_type, changes = {})
      GuardianEvent.create!(guardian:, actor:, event_type:, metadata: { "changes" => changes })
    end

    def safe_changes(guardian)
      audited_changes(guardian, FIELDS).transform_values.with_index do |value, index|
        audited_changes(guardian, FIELDS).keys[index] == "internal_notes" ? { "changed" => true } : value
      end
    end
  end
end
