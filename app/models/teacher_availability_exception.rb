class TeacherAvailabilityException < ApplicationRecord
  EXCEPTION_TYPES = %w[unavailable available_override].freeze
  STATUSES = %w[active cancelled archived].freeze

  belongs_to :teacher_profile, inverse_of: :availability_exceptions
  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_teacher_availability_exceptions
  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_teacher_availability_exceptions
  has_many :events, class_name: "TeacherAvailabilityExceptionEvent", dependent: :restrict_with_exception

  attr_readonly :public_id
  before_validation :normalize_values
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\ATEX-[A-Z0-9]{10}\z/ }
  validates :exception_date, presence: true
  validates :exception_type, inclusion: { in: EXCEPTION_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :time_zone, inclusion: { in: ->(_) { ActiveSupport::TimeZone.all.map(&:name) } }
  validates :reason, length: { maximum: 1_000 }, allow_blank: true
  validate :paired_times
  validate :time_order
  validate :no_overlapping_active_exception
  validate :teacher_is_valid

  scope :active, -> { where(status: "active") }
  scope :visible, -> { where.not(status: "archived") }
  scope :recent_first, -> { order(exception_date: :desc) }

  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  private

  def normalize_values
    self.time_zone = EffectiveTimeZone.for(teacher_profile&.user) if time_zone.blank?
  end

  def generate_public_id
    self.public_id ||= "TEX-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def paired_times
    errors.add(:base, :times_must_be_paired) if starts_at_local.present? != ends_at_local.present?
  end

  def time_order
    return if starts_at_local.blank? || ends_at_local.blank?

    errors.add(:ends_at_local, :after_start) unless ends_at_local > starts_at_local
  end

  def no_overlapping_active_exception
    return unless active? && teacher_profile && exception_date

    overlap = teacher_profile.availability_exceptions.active.where.not(id: id).where(
      exception_date:, exception_type:
    )
    errors.add(:base, :overlaps_existing) if overlap.any? { |record| overlaps?(record) }
  end

  def overlaps?(record)
    return true if starts_at_local.blank? || record.starts_at_local.blank?

    starts_at_local < record.ends_at_local && ends_at_local > record.starts_at_local
  end

  def teacher_is_valid
    return if teacher_profile&.employment_status == "active" && !teacher_profile.archived?

    errors.add(:teacher_profile,
               :not_active)
  end
end
