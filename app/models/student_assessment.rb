class StudentAssessment < ApplicationRecord
  STATUSES = %w[draft submitted reviewed published archived].freeze
  LETTER_GRADES = %w[A+ A B+ B C D F].freeze

  belongs_to :enrollment
  belongs_to :student_profile
  belongs_to :teacher_profile
  belongs_to :scheduled_lesson, optional: true
  belongs_to :assessment_template
  belongs_to :reviewer, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  has_many :scores, class_name: "AssessmentScore", dependent: :restrict_with_exception
  has_many :events, class_name: "StudentAssessmentEvent", dependent: :restrict_with_exception

  attr_readonly :public_id, :enrollment_id, :student_profile_id, :assessment_template_id
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AASM-[A-Z0-9]{10}\z/ }
  validates :assessment_date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :overall_score, numericality: { in: 0..100 }, allow_nil: true
  validates :letter_grade, inclusion: { in: LETTER_GRADES }, allow_blank: true
  validates :notes, length: { maximum: 5_000 }, allow_blank: true
  validate :ownership_consistency

  scope :recent_first, -> { order(assessment_date: :desc, id: :desc) }
  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }
  def editable? = draft?

  private

  def generate_public_id = self.public_id ||= "ASM-#{SecureRandom.alphanumeric(10).upcase}"

  def ownership_consistency
    errors.add(:student_profile, :inconsistent) if enrollment && enrollment.student_profile_id != student_profile_id
    return unless scheduled_lesson

    if scheduled_lesson.course_offering_id != enrollment&.course_offering_id
      errors.add(:scheduled_lesson, :inconsistent)
    end
    errors.add(:teacher_profile, :inconsistent) if scheduled_lesson.teacher_profile_id != teacher_profile_id
    return if scheduled_lesson.enrollments.exists?(id: enrollment_id)

    errors.add(:enrollment, :not_a_lesson_participant)
  end
end
