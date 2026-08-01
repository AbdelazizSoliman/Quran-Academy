class ScheduledLessonEnrollment < ApplicationRecord
  PARTICIPATION_STATUSES = %w[expected removed].freeze

  belongs_to :scheduled_lesson, inverse_of: :scheduled_lesson_enrollments
  belongs_to :enrollment, inverse_of: :scheduled_lesson_enrollments
  belongs_to :added_by, class_name: "User", optional: true
  has_one :lesson_attendance, inverse_of: :scheduled_lesson_enrollment, dependent: :restrict_with_exception

  validates :participation_status, inclusion: { in: PARTICIPATION_STATUSES }
  validates :enrollment_id, uniqueness: { scope: :scheduled_lesson_id }
  validate :same_offering
  validate :operational_enrollment

  def expected? = participation_status == "expected"

  private

  def same_offering
    return unless scheduled_lesson && enrollment

    return if scheduled_lesson.course_offering_id == enrollment.course_offering_id

    errors.add(:enrollment,
               :different_offering)
  end

  def operational_enrollment
    return unless enrollment

    errors.add(:enrollment, :not_operational) unless enrollment.status.in?(%w[approved active paused])
  end
end
