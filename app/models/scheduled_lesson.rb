class ScheduledLesson < ApplicationRecord
  has_many :notifications, as: :source, dependent: :restrict_with_exception
  STATUSES = %w[draft scheduled in_progress completed cancelled archived].freeze
  DELIVERY_MODES = %w[online onsite hybrid].freeze
  SCHEDULING_SOURCES = %w[manual recurring rescheduled imported].freeze
  OPERATIONAL_STATUSES = %w[scheduled in_progress].freeze
  ATTENDANCE_STATUSES = %w[not_opened open locked reopened].freeze
  TEACHER_ATTENDANCE_STATUSES = %w[not_checked_in on_time late absent administrator_override].freeze

  belongs_to :course_offering, inverse_of: :scheduled_lessons, optional: true
  belongs_to :teacher_profile, inverse_of: :scheduled_lessons
  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_scheduled_lessons
  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_scheduled_lessons
  belongs_to :cancelled_by, class_name: "User", optional: true
  belongs_to :attendance_locked_by, class_name: "User", optional: true
  belongs_to :attendance_reopened_by, class_name: "User", optional: true
  belongs_to :enrollment_lesson_schedule_slot, optional: true
  has_many :scheduled_lesson_enrollments, inverse_of: :scheduled_lesson, dependent: :restrict_with_exception
  has_many :enrollments, through: :scheduled_lesson_enrollments
  has_many :lesson_attendances, inverse_of: :scheduled_lesson, dependent: :restrict_with_exception
  has_one :lesson_report, inverse_of: :scheduled_lesson, dependent: :restrict_with_exception
  has_many :teacher_payroll_items, dependent: :restrict_with_exception
  has_many :communication_logs, dependent: :restrict_with_exception
  has_many :events, class_name: "ScheduledLessonEvent", inverse_of: :scheduled_lesson,
                    dependent: :restrict_with_exception

  attr_readonly :public_id, :academy_time_zone
  before_validation :normalize_values
  before_validation :normalize_online_meeting_url
  before_validation :generate_public_id, on: :create
  before_validation :snapshot_academy_zone, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\ALSN-[A-Z0-9]{10}\z/ }
  validates :title_ar, :title_en, presence: true, length: { maximum: 200 }
  validates :status, inclusion: { in: STATUSES }
  validates :delivery_mode, inclusion: { in: DELIVERY_MODES }
  validates :scheduling_source, inclusion: { in: SCHEDULING_SOURCES }
  validates :attendance_status, inclusion: { in: ATTENDANCE_STATUSES }
  validates :teacher_attendance_status, inclusion: { in: TEACHER_ATTENDANCE_STATUSES }
  validates :completion_notes, :operation_notes, length: { maximum: 2_000 }, allow_blank: true
  validates :academy_time_zone, inclusion: { in: ->(_) { ActiveSupport::TimeZone.all.map(&:name) } }
  validates :recurrence_date, presence: true, if: :enrollment_lesson_schedule_slot_id?
  validates :enrollment_lesson_schedule_slot_id, uniqueness: { scope: :recurrence_date }, allow_nil: true
  validate :online_meeting_url_format
  validates :cancellation_reason, presence: true, if: :cancelled?
  validate :time_order
  validate :delivery_requirements, if: :scheduled_or_later?

  scope :operational, -> { where(status: OPERATIONAL_STATUSES) }
  scope :chronological, -> { order(starts_at: :asc, id: :asc) }

  def attendance_editable? = attendance_status.in?(%w[open reopened])
  def attendance_locked? = attendance_status == "locked"
  def unresolved_attendance_count = lesson_attendances.unresolved.count

  def completion_confirmation_key
    unresolved_attendance_count.zero? ? "attendance.messages.complete_confirmation_clear" :
                                        "attendance.messages.complete_confirmation"
  end

  def online_meeting_join_url
    OnlineMeetingUrl.normalize(effective_online_meeting_url)
  end

  def effective_online_meeting_url = online_meeting_url.presence || teacher_profile&.online_meeting_url
  def safe_online_meeting_join_url = OnlineMeetingUrl.safe(effective_online_meeting_url)

  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  private

  def normalize_values
    self.academy_time_zone = EffectiveTimeZone.for if academy_time_zone.blank?
  end

  def normalize_online_meeting_url
    self.online_meeting_url = OnlineMeetingUrl.normalize(online_meeting_url) if online_meeting_url.present?
  end

  def generate_public_id
    self.public_id ||= "LSN-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def snapshot_academy_zone
    self.academy_time_zone ||= EffectiveTimeZone.for
  end

  def time_order
    errors.add(:ends_at, :after_start) if starts_at && ends_at && ends_at <= starts_at
  end

  def scheduled_or_later?
    status.in?(%w[scheduled in_progress completed])
  end

  def delivery_requirements
    if delivery_mode.in?(%w[online hybrid]) && safe_online_meeting_join_url.blank?
      errors.add(:online_meeting_url, :required)
    end
    errors.add(:location_name, :required) if delivery_mode.in?(%w[onsite hybrid]) && location_name.blank?
  end

  def online_meeting_url_format
    return if online_meeting_url.blank?

    errors.add(:online_meeting_url, :invalid_url) unless OnlineMeetingUrl.valid?(online_meeting_url)
  end
end
