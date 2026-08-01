class CommunicationLogEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = CommunicationLog::STATUSES
  belongs_to :communication_log, inverse_of: :events
  belongs_to :actor, class_name: "User"
  validates :event_type, inclusion: { in: EVENT_TYPES }
end
