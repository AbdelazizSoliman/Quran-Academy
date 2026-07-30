class ProgramEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = %w[created updated activated deactivated archived restored].freeze
  belongs_to :program, inverse_of: :events
  belongs_to :actor, class_name: "User"
  validates :event_type, inclusion: { in: EVENT_TYPES }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
