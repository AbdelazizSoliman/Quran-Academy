class Enrollment < ApplicationRecord
  STATUSES = %w[pending approved waitlisted active paused completed withdrawn rejected cancelled transferred].freeze
  TERMINAL_STATUSES = %w[completed withdrawn rejected cancelled transferred].freeze
  APPLICATION_SOURCES = %w[administrator student_request guardian_request referral transfer imported other].freeze
  PLACEMENT_STATUSES = %w[not_required pending in_review completed waived].freeze
  PLACEMENT_METHODS = %w[
    profile_review teacher_assessment student_self_report guardian_report
    previous_academy_record administrator_override
  ].freeze
  EXIT_REASONS = %w[
    completed_program student_request guardian_request schedule_conflict academic_mismatch
    inactive_student capacity_issue academy_cancelled transferred_to_other_offering other
  ].freeze
  EDITABLE_FIELDS = %w[
    application_source student_goals_snapshot preferred_schedule_notes placement_notes administrator_notes
  ].freeze

  belongs_to :student_profile
  belongs_to :course_offering
  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_enrollments
  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_enrollments
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :ended_by, class_name: "User", optional: true
  has_many :events, class_name: "EnrollmentEvent", dependent: :restrict_with_exception
  has_many :scheduled_lesson_enrollments, inverse_of: :enrollment, dependent: :restrict_with_exception
  has_many :scheduled_lessons, through: :scheduled_lesson_enrollments
  has_many :lesson_schedules, class_name: "EnrollmentLessonSchedule", dependent: :restrict_with_exception
  has_many :student_assessments, dependent: :restrict_with_exception
  has_many :certificates, dependent: :restrict_with_exception

  attr_readonly :public_id, :student_profile_id, :course_offering_id
  before_validation :generate_public_id, on: :create
  before_validation :apply_defaults, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AENR-[A-Z0-9]{10}\z/ }
  validates :student_profile_id, uniqueness: { scope: :course_offering_id }
  validates :status, inclusion: { in: STATUSES }
  validates :application_source, inclusion: { in: APPLICATION_SOURCES }
  validates :placement_status, inclusion: { in: PLACEMENT_STATUSES }
  validates :placement_method, inclusion: { in: PLACEMENT_METHODS }, allow_blank: true
  validates :exit_reason, inclusion: { in: EXIT_REASONS }, allow_blank: true
  validates :starting_quran_level, inclusion: { in: StudentProfile::QURAN_LEVELS }, allow_blank: true
  validates :starting_reading_level, inclusion: { in: StudentProfile::READING_LEVELS }, allow_blank: true
  validates :starting_tajweed_level, inclusion: { in: StudentProfile::TAJWEED_LEVELS }, allow_blank: true
  validates :starting_memorization_level, inclusion: { in: StudentProfile::MEMORIZATION_LEVELS }, allow_blank: true
  validates :starting_memorized_juz_count, numericality: { only_integer: true, in: 0..30 }, allow_nil: true
  validates :exit_reason, presence: true, if: :terminal?
  validates :exit_notes, presence: true, if: -> { exit_reason == "other" }
  validate :student_eligibility
  validate :lifecycle_date_order

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
  scope :capacity_consuming, -> { where(status: CourseOffering::CAPACITY_STATUSES) }

  def terminal? = status.in?(TERMINAL_STATUSES)
  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  private

  def generate_public_id
    self.public_id ||= "ENR-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def apply_defaults
    self.applied_on ||= Date.current
    return unless student_profile

    copy_student_snapshot
    self.placement_status = course_offering&.placement_required? ? "pending" : "not_required"
  end

  # Student enrollment keeps a point-in-time snapshot of the profile's learning context.
  # rubocop:disable Metrics/AbcSize
  def copy_student_snapshot
    self.student_goals_snapshot ||= student_profile.learning_goals
    self.starting_quran_level ||= student_profile.current_quran_level
    self.starting_reading_level ||= student_profile.reading_level
    self.starting_tajweed_level ||= student_profile.tajweed_level
    self.starting_memorization_level ||= student_profile.memorization_level
    self.starting_memorized_juz_count ||= student_profile.memorized_juz_count
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/CyclomaticComplexity
  def student_eligibility
    errors.add(:student_profile, :must_be_available) if student_profile&.archived? ||
                                                        student_profile&.learning_status == "departed"
    errors.add(:student_profile, :must_be_student) unless student_profile&.user&.student?
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def lifecycle_date_order
    dates = [applied_on, approved_on, started_on, ended_on].compact
    errors.add(:base, :invalid_date_order) unless dates == dates.sort
  end
end
