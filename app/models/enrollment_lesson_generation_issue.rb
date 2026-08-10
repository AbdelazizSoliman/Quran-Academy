class EnrollmentLessonGenerationIssue < ApplicationRecord
  belongs_to :enrollment_lesson_schedule_slot

  validates :recurrence_date, presence: true,
                              uniqueness: { scope: :enrollment_lesson_schedule_slot_id }
  validates :reason_code, presence: true

  scope :unresolved, -> { where(resolved_at: nil) }
end
