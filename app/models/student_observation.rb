class StudentObservation < ApplicationRecord
  CATEGORIES = %w[quran_reading memorization pronunciation tajweed attention engagement behaviour motivation
                  teaching_strategy other].freeze
  VISIBILITY_LEVELS = StudentLearningProfileItem::VISIBILITY_LEVELS
  SENSITIVITY_LEVELS = StudentLearningProfileItem::SENSITIVITY_LEVELS
  SOURCES = %w[teacher_entry admin_entry lesson].freeze

  belongs_to :student_profile, inverse_of: :student_observations
  belongs_to :teacher_profile, inverse_of: :student_observations
  belongs_to :scheduled_lesson, optional: true, inverse_of: :student_observations
  belongs_to :created_by, class_name: "User", inverse_of: :created_student_observations

  attr_readonly :student_profile_id, :teacher_profile_id, :scheduled_lesson_id, :created_by_id, :category,
                :observation, :observed_at, :visibility, :sensitivity, :source

  before_validation :apply_defaults
  before_destroy :prevent_destruction

  validates :category, inclusion: { in: CATEGORIES }
  validates :observation, presence: true, length: { maximum: 5_000 }
  validates :observed_at, presence: true
  validates :visibility, inclusion: { in: VISIBILITY_LEVELS }
  validates :sensitivity, inclusion: { in: SENSITIVITY_LEVELS }
  validates :source, inclusion: { in: SOURCES }
  validate :lesson_context_consistency
  validate :creator_attribution

  private

  def apply_defaults
    self.observed_at ||= Time.current
    self.sensitivity ||= "standard"
    self.visibility ||= "internal"
    self.visibility = "internal" if sensitivity.in?(%w[sensitive highly_sensitive]) && visibility.blank?
  end

  def lesson_context_consistency
    return unless scheduled_lesson

    errors.add(:scheduled_lesson, :teacher_mismatch) if scheduled_lesson.teacher_profile_id != teacher_profile_id
    participant = scheduled_lesson.scheduled_lesson_enrollments.expected.for_student_profile_ids([student_profile_id])
    errors.add(:scheduled_lesson, :student_mismatch) unless participant.exists?
  end

  def creator_attribution
    return if source == "admin_entry" && created_by&.admin?
    return if created_by_id == teacher_profile&.user_id

    errors.add(:created_by, :teacher_mismatch)
  end

  def prevent_destruction
    errors.add(:base, :immutable)
    throw(:abort)
  end
end
