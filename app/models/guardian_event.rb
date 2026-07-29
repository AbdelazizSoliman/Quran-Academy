class GuardianEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = %w[created updated archived restored contact_information_changed].freeze

  belongs_to :guardian, inverse_of: :events
  belongs_to :actor, class_name: "User", inverse_of: :guardian_events
  validates :event_type, inclusion: { in: EVENT_TYPES }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
