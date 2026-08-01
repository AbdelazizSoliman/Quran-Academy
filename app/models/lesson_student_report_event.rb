class LessonStudentReportEvent < ApplicationRecord
  include SafeAuditMetadata

  EVENT_TYPES = %w[created updated completed withheld restored].freeze
  belongs_to :lesson_student_report, inverse_of: :events
  belongs_to :actor, class_name: "User"
  validates :event_type, inclusion: { in: EVENT_TYPES }
end
