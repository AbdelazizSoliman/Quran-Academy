class LessonAttendance < ApplicationRecord
  STATUSES = %w[pending present late absent excused_absence left_early lesson_cancelled not_applicable].freeze
  FINAL_STATUSES = STATUSES - %w[pending]

  belongs_to :scheduled_lesson, inverse_of: :lesson_attendances
  belongs_to :scheduled_lesson_enrollment, inverse_of: :lesson_attendance
  belongs_to :recorded_by, class_name: "User", optional: true
  belongs_to :last_adjusted_by, class_name: "User", optional: true
  has_many :events, class_name: "LessonAttendanceEvent", inverse_of: :lesson_attendance,
                    dependent: :restrict_with_exception

  attr_readonly :public_id, :scheduled_lesson_id, :scheduled_lesson_enrollment_id
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AATT-[A-Z0-9]{10}\z/ }
  validates :scheduled_lesson_enrollment_id, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :minutes_late, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :excuse_reason, presence: true, if: :excused_absence?
  validates :excuse_reason, :adjustment_reason, length: { maximum: 500 }, allow_blank: true
  validates :notes, length: { maximum: 2_000 }, allow_blank: true
  validate :participant_belongs_to_lesson
  validate :departure_follows_arrival
  validate :departure_requires_attendance

  scope :unresolved, -> { where(status: "pending") }
  scope :finalized, -> { where(status: FINAL_STATUSES) }
  scope :chronological, -> { order(created_at: :asc, id: :asc) }

  delegate :enrollment, to: :scheduled_lesson_enrollment
  delegate :student_profile, to: :enrollment

  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  private

  def generate_public_id
    self.public_id ||= "ATT-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def participant_belongs_to_lesson
    return unless scheduled_lesson && scheduled_lesson_enrollment
    return if scheduled_lesson_enrollment.scheduled_lesson_id == scheduled_lesson_id

    errors.add(:scheduled_lesson_enrollment, :different_lesson)
  end

  def departure_follows_arrival
    return unless departure_at && arrival_at && departure_at < arrival_at

    errors.add(:departure_at, :before_arrival)
  end

  def departure_requires_attendance
    return if departure_at.blank? || status.in?(%w[present late left_early])

    errors.add(:departure_at, :invalid_status)
  end
end
