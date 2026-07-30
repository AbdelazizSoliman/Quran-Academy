class CourseOfferingEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = %w[created updated opened closed started completed cancelled archived restored capacity_changed].freeze
  belongs_to :course_offering, inverse_of: :events
  belongs_to :actor, class_name: "User"
  validates :event_type, inclusion: { in: EVENT_TYPES }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
