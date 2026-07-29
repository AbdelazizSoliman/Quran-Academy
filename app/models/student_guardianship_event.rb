class StudentGuardianshipEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = %w[created updated made_primary ended restored legal_authority_changed
                   communication_preferences_changed].freeze

  belongs_to :student_guardianship, inverse_of: :events
  belongs_to :actor, class_name: "User", inverse_of: :student_guardianship_events
  validates :event_type, inclusion: { in: EVENT_TYPES }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
