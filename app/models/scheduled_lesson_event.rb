class ScheduledLessonEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = %w[created updated scheduled rescheduled started completed cancelled archived participant_added
                   participant_removed teacher_checked_in teacher_marked_absent attendance_opened attendance_locked
                   attendance_reopened].freeze
  belongs_to :scheduled_lesson, inverse_of: :events
  belongs_to :actor, class_name: "User"
  validates :event_type, inclusion: { in: EVENT_TYPES }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
