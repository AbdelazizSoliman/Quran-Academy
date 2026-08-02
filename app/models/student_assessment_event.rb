class StudentAssessmentEvent < ApplicationRecord
  include SafeAuditMetadata
  EVENT_TYPES = %w[created updated submitted reviewed published archived].freeze
  belongs_to :student_assessment, inverse_of: :events
  belongs_to :actor, class_name: "User"
  validates :event_type, inclusion: { in: EVENT_TYPES }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
