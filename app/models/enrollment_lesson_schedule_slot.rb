class EnrollmentLessonScheduleSlot < ApplicationRecord
  belongs_to :enrollment_lesson_schedule, inverse_of: :slots
  has_many :scheduled_lessons, dependent: :restrict_with_exception
  has_many :generation_issues, class_name: "EnrollmentLessonGenerationIssue", dependent: :restrict_with_exception

  validates :weekday, inclusion: { in: StudentProfile::WEEKDAYS }
  validates :starts_at_local, presence: true
  validates :weekday, uniqueness: { scope: %i[enrollment_lesson_schedule_id starts_at_local] }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
