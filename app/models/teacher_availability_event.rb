class TeacherAvailabilityEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = %w[created updated activated deactivated archived].freeze
  belongs_to :teacher_availability, inverse_of: :events
  belongs_to :actor, class_name: "User"
  validates :event_type, inclusion: { in: EVENT_TYPES }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
