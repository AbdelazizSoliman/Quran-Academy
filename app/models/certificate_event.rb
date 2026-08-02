class CertificateEvent < ApplicationRecord
  include SafeAuditMetadata
  EVENT_TYPES = %w[created updated archived].freeze
  belongs_to :certificate, inverse_of: :events
  belongs_to :actor, class_name: "User"
  validates :event_type, inclusion: { in: EVENT_TYPES }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
