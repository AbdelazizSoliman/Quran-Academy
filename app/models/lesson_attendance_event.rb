class LessonAttendanceEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = %w[initialized arrival_recorded marked_present marked_late marked_absent excused
                   departure_recorded marked_left_early adjusted locked reopened marked_not_applicable].freeze

  belongs_to :lesson_attendance, inverse_of: :events
  belongs_to :actor, class_name: "User"

  validates :event_type, inclusion: { in: EVENT_TYPES }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
