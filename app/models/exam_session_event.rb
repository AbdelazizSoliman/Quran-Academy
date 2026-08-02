class ExamSessionEvent < ApplicationRecord
  include SafeAuditMetadata
  EVENT_TYPES = %w[created updated scheduled completed reviewed published archived].freeze
  belongs_to :exam_session, inverse_of: :events
  belongs_to :actor, class_name: "User"
  validates :event_type, inclusion: { in: EVENT_TYPES }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
