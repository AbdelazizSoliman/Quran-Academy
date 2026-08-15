class EnrollmentLessonSchedule < ApplicationRecord
  STATUSES = %w[active superseded cancelled].freeze

  belongs_to :enrollment, optional: true
  belongs_to :student_profile, optional: true, inverse_of: :direct_lesson_schedules
  belongs_to :teacher_profile
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true
  has_many :slots, -> { order(:position, :id) }, class_name: "EnrollmentLessonScheduleSlot",
                                                 dependent: :restrict_with_exception,
                                                 inverse_of: :enrollment_lesson_schedule
  has_many :events, class_name: "EnrollmentLessonScheduleEvent", dependent: :restrict_with_exception
  has_many :generation_issues, through: :slots
  has_many :scheduled_lessons, through: :slots

  attr_readonly :public_id, :enrollment_id, :student_profile_id
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AELS-[A-Z0-9]{10}\z/ }
  validates :status, inclusion: { in: STATUSES }
  validates :lesson_duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :time_zone, inclusion: { in: ->(_) { ActiveSupport::TimeZone.all.map(&:name) } }
  validates :starts_on, presence: true
  validates :enrollment_id, uniqueness: { conditions: -> { where(status: "active") } }, if: :active?, allow_nil: true
  validates :student_profile_id, uniqueness: { conditions: -> { where(status: "active") } }, if: :active?,
                                 allow_nil: true
  validate :date_order
  validate :teacher_is_usable
  validate :enrollment_is_individual
  validate :exactly_one_participant_reference

  scope :active, -> { where(status: "active") }
  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  def weekly_lesson_count = slots.size

  # Direct fee-plan-only schedules point at a StudentProfile directly; enrollment-backed
  # schedules only carry an Enrollment, whose own student_profile is the fallback.
  def student_profile
    super || enrollment&.student_profile
  end

  private

  def generate_public_id
    self.public_id ||= "ELS-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def date_order
    errors.add(:ends_on, :before_start) if starts_on && ends_on && ends_on < starts_on
  end

  def teacher_is_usable
    return if teacher_profile&.employment_status == "active" && !teacher_profile.archived?

    errors.add(:teacher_profile, :not_active)
  end

  def enrollment_is_individual
    return unless student_profile&.session_type == "group"

    errors.add(:enrollment, :group_not_supported)
  end

  def exactly_one_participant_reference
    return errors.add(:base, :participant_required) if enrollment.blank? && student_profile_id.blank?

    errors.add(:base, :participant_conflict) if enrollment.present? && student_profile_id.present?
  end
end
