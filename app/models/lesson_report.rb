class LessonReport < ApplicationRecord
  has_many :notifications, as: :source, dependent: :restrict_with_exception
  STATUSES = %w[draft submitted reviewed locked reopened archived].freeze
  ENGAGEMENT_LEVELS = %w[not_assessed low inconsistent engaged highly_engaged].freeze
  PROGRESS_LEVELS = %w[not_assessed needs_support developing meeting_expectations above_expectations excellent].freeze

  belongs_to :scheduled_lesson, inverse_of: :lesson_report
  belongs_to :teacher_profile
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  belongs_to :submitted_by, class_name: "User", optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true
  belongs_to :locked_by, class_name: "User", optional: true
  belongs_to :reopened_by, class_name: "User", optional: true
  has_many :lesson_student_reports, inverse_of: :lesson_report, dependent: :restrict_with_exception
  has_many :events, class_name: "LessonReportEvent", inverse_of: :lesson_report,
                    dependent: :restrict_with_exception
  has_many :communication_logs, dependent: :restrict_with_exception

  attr_readonly :public_id, :scheduled_lesson_id, :teacher_profile_id
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\ALRP-[A-Z0-9]{10}\z/ }
  validates :scheduled_lesson_id, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :overall_engagement, inclusion: { in: ENGAGEMENT_LEVELS }
  validates :overall_progress, inclusion: { in: PROGRESS_LEVELS }
  validates :report_language, inclusion: { in: %w[ar en] }
  validates :lesson_summary, :topics_covered, :general_teacher_notes, :general_homework, :next_lesson_plan,
            length: { maximum: 5_000 }, allow_blank: true
  validate :teacher_matches_lesson

  scope :student_visible, -> { where(status: %w[reviewed locked]) }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  def teacher_editable? = status.in?(%w[draft reopened])
  def unresolved_entries? = lesson_student_reports.exists?(status: "pending")

  private

  def generate_public_id
    self.public_id ||= "LRP-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def teacher_matches_lesson
    return unless scheduled_lesson && teacher_profile_id != scheduled_lesson.teacher_profile_id

    errors.add(:teacher_profile, :different_teacher)
  end
end
