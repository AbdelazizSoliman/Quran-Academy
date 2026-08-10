class EnrollmentLessonScheduleEvent < ApplicationRecord
  belongs_to :enrollment_lesson_schedule
  belongs_to :actor, class_name: "User"

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
