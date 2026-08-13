class ScheduledLessonEnrollment < ApplicationRecord
  PARTICIPATION_STATUSES = %w[expected removed].freeze

  belongs_to :scheduled_lesson, inverse_of: :scheduled_lesson_enrollments
  belongs_to :enrollment, inverse_of: :scheduled_lesson_enrollments, optional: true
  belongs_to :student_profile, optional: true, inverse_of: :direct_scheduled_lesson_enrollments
  belongs_to :added_by, class_name: "User", optional: true
  has_one :lesson_attendance, inverse_of: :scheduled_lesson_enrollment, dependent: :restrict_with_exception
  has_many :lesson_student_reports, dependent: :restrict_with_exception

  validates :participation_status, inclusion: { in: PARTICIPATION_STATUSES }
  validates :enrollment_id, uniqueness: { scope: :scheduled_lesson_id }, allow_nil: true
  validates :student_profile_id, uniqueness: { scope: :scheduled_lesson_id }, allow_nil: true
  validate :same_offering
  validate :operational_enrollment
  validate :exactly_one_participant_reference

  def expected? = participation_status == "expected"
  scope :expected, -> { where(participation_status: "expected") }

  # Matches participations for the given student_profile id(s) whether they're direct or
  # enrollment-backed — the one shared resolver query-side callers should reuse instead of
  # re-deriving the enrollment-vs-direct join themselves.
  scope :for_student_profile_ids, lambda { |ids|
    where(student_profile_id: ids).or(where(enrollment_id: Enrollment.where(student_profile_id: ids).select(:id)))
  }

  # Direct fee-plan-only participants point at a StudentProfile directly; enrollment-backed
  # participants only carry an Enrollment, whose own student_profile is the fallback.
  def student_profile
    super || enrollment&.student_profile
  end

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

  def exactly_one_participant_reference
    return errors.add(:base, :participant_required) if enrollment.blank? && student_profile_id.blank?

    errors.add(:base, :participant_conflict) if enrollment.present? && student_profile_id.present?
  end
end
