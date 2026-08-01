class TeacherAvailability < ApplicationRecord
  WEEKDAYS = %w[monday tuesday wednesday thursday friday saturday sunday].freeze
  AVAILABILITY_TYPES = %w[teaching administrative general].freeze
  STATUSES = %w[active inactive archived].freeze

  belongs_to :teacher_profile, inverse_of: :availabilities
  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_teacher_availabilities
  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_teacher_availabilities
  has_many :events, class_name: "TeacherAvailabilityEvent", dependent: :restrict_with_exception

  attr_readonly :public_id
  before_validation :normalize_values
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\ATAV-[A-Z0-9]{10}\z/ }
  validates :weekday, inclusion: { in: WEEKDAYS }
  validates :availability_type, inclusion: { in: AVAILABILITY_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :time_zone, inclusion: { in: ->(_) { ActiveSupport::TimeZone.all.map(&:name) } }
  validates :effective_from, presence: true
  validates :notes, length: { maximum: 5_000 }, allow_blank: true
  validate :time_order
  validate :effective_date_order
  validate :no_overlapping_active_range
  validate :teacher_is_valid

  scope :active, -> { where(status: "active") }
  scope :teaching_capable, -> { where(availability_type: %w[teaching general]) }
  scope :visible, -> { where.not(status: "archived") }
  scope :chronological, -> { order(:weekday, :starts_at_local) }

  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  private

  def normalize_values
    self.weekday = weekday.to_s.downcase
    self.time_zone = "Africa/Cairo" if time_zone.blank?
  end

  def generate_public_id
    self.public_id ||= "TAV-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def time_order
    return if starts_at_local.blank? || ends_at_local.blank?

    errors.add(:ends_at_local, :after_start) unless ends_at_local > starts_at_local
  end

  def effective_date_order
    return if effective_from.blank? || effective_until.blank?

    errors.add(:effective_until, :after_start) if effective_until < effective_from
  end

  def no_overlapping_active_range
    return unless overlap_validation_applicable?

    errors.add(:base, :overlaps_existing) if overlapping_time_ranges.any? { |record| effective_dates_overlap?(record) }
  end

  def overlap_validation_applicable?
    active? && teacher_profile && effective_from && starts_at_local && ends_at_local
  end

  def overlapping_time_ranges
    teacher_profile.availabilities.active.where.not(id:).where(weekday:, availability_type:, time_zone:)
                   .where("starts_at_local < ? AND ends_at_local > ?", ends_at_local, starts_at_local)
  end

  def effective_dates_overlap?(record)
    (effective_until.blank? || record.effective_from <= effective_until) &&
      (record.effective_until.blank? || effective_from <= record.effective_until)
  end

  def teacher_is_valid
    return if teacher_profile&.employment_status == "active" && !teacher_profile.archived?

    errors.add(:teacher_profile,
               :not_active)
  end
end
