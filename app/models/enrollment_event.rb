class EnrollmentEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = %w[
    created updated approved waitlisted rejected activated paused resumed completed
    withdrawn cancelled transferred placement_completed placement_waived
  ].freeze
  belongs_to :enrollment, inverse_of: :events
  belongs_to :actor, class_name: "User"
  validates :event_type, inclusion: { in: EVENT_TYPES }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
