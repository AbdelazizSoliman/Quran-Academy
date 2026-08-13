class LessonStudentReport < ApplicationRecord
  STATUSES = %w[pending completed not_applicable withheld].freeze
  READING_QUALITIES = %w[not_assessed needs_support developing good very_good excellent].freeze
  MEMORIZATION_RESULTS = %w[not_assessed new_assignment needs_revision partially_memorized memorized_with_prompts
                            memorized excellent].freeze
  REVISION_RESULTS = %w[not_assessed weak needs_repetition acceptable good very_good excellent].freeze
  TAJWEED_TOPICS = %w[makharij sifat madd ghunnah qalqalah noon_sakinah_tanween meem_sakinah waqf_ibtida
                      general_recitation other].freeze
  ENGAGEMENT_LEVELS = LessonReport::ENGAGEMENT_LEVELS
  PERFORMANCE_LEVELS = LessonReport::PROGRESS_LEVELS

  belongs_to :lesson_report, inverse_of: :lesson_student_reports
  belongs_to :scheduled_lesson_enrollment
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  has_many :events, class_name: "LessonStudentReportEvent", inverse_of: :lesson_student_report,
                    dependent: :restrict_with_exception
  has_many :communication_logs, dependent: :restrict_with_exception

  attr_readonly :public_id, :lesson_report_id, :scheduled_lesson_enrollment_id
  before_validation :generate_public_id, on: :create
  before_validation :normalize_tajweed_topics

  validates :public_id, presence: true, uniqueness: true, format: { with: /\ALSR-[A-Z0-9]{10}\z/ }
  validates :scheduled_lesson_enrollment_id, uniqueness: { scope: :lesson_report_id }
  validates :status, inclusion: { in: STATUSES }
  validates :reading_quality, inclusion: { in: READING_QUALITIES }
  validates :memorization_result, inclusion: { in: MEMORIZATION_RESULTS }
  validates :revision_result, inclusion: { in: REVISION_RESULTS }
  validates :engagement_level, inclusion: { in: ENGAGEMENT_LEVELS }
  validates :performance_level, inclusion: { in: PERFORMANCE_LEVELS }
  validates :reading_material, :reading_from, :reading_to, :memorization_material, :memorization_from,
            :memorization_to, :revision_material, length: { maximum: 250 }, allow_blank: true
  validates :reading_notes, :memorization_notes, :revision_notes, :tajweed_observations, :mistakes_summary,
            :strengths, :areas_for_improvement, :homework, :next_lesson_target, :private_teacher_notes,
            :student_visible_notes, :guardian_visible_notes, length: { maximum: 5_000 }, allow_blank: true
  validate :participant_matches_lesson
  validate :valid_tajweed_topics

  delegate :enrollment, :student_profile, to: :scheduled_lesson_enrollment
  delegate :scheduled_lesson, to: :lesson_report

  scope :student_visible, -> { where(status: "completed") }

  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  private

  def generate_public_id
    self.public_id ||= "LSR-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def normalize_tajweed_topics
    self.tajweed_topics = Array(tajweed_topics).compact_blank.map(&:to_s).uniq
  end

  def participant_matches_lesson
    return unless lesson_report && scheduled_lesson_enrollment
    return if scheduled_lesson_enrollment.scheduled_lesson_id == lesson_report.scheduled_lesson_id

    errors.add(:scheduled_lesson_enrollment, :different_lesson)
  end

  def valid_tajweed_topics
    errors.add(:tajweed_topics, :invalid) if (tajweed_topics - TAJWEED_TOPICS).any?
  end
end
