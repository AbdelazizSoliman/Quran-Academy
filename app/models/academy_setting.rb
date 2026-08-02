class AcademySetting < ApplicationRecord
  SINGLETON_KEY = "current".freeze
  INTERFACE_LOCALES = %w[ar en].freeze
  TEACHING_LANGUAGES = %w[ar en fr de tr ur].freeze
  WEEKDAYS = %w[sunday monday tuesday wednesday thursday friday saturday].freeze
  COMPENSATION_TYPES = %w[per_lesson hourly monthly].freeze
  PAYROLL_PERIODS = %w[weekly biweekly monthly].freeze
  INVITATION_DELIVERY_MODES = %w[email_only whatsapp_only email_and_whatsapp].freeze
  BILLING_CYCLES = %w[per_lesson weekly monthly package].freeze
  CURRENCY_PATTERN = /\A[A-Z]{3}\z/
  COUNTRY_PATTERN = /\A[A-Z]{2}\z/

  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_academy_settings
  has_many :events, class_name: "AcademySettingEvent", dependent: :restrict_with_exception

  validates :singleton_key, inclusion: { in: [SINGLETON_KEY] }, uniqueness: true
  validates :academy_name, presence: true, length: { maximum: 150 }
  validates :legal_name, :short_name, length: { maximum: 150 }, allow_blank: true
  validates :description, length: { maximum: 2_000 }, allow_blank: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :website_url, format: { with: %r{\Ahttps?://[^\s]+\z} }, allow_blank: true
  validates :contact_phone, :whatsapp_number, length: { maximum: 30 }, allow_blank: true
  validates :country_code, format: { with: COUNTRY_PATTERN }
  validates :default_locale, inclusion: { in: INTERFACE_LOCALES }
  validates :default_time_zone, inclusion: { in: ->(_) { ActiveSupport::TimeZone.all.map(&:name) } }
  validates :payroll_currency, :billing_currency, format: { with: CURRENCY_PATTERN }
  validates :default_teacher_compensation_type, inclusion: { in: COMPENSATION_TYPES }
  validates :payroll_period, inclusion: { in: PAYROLL_PERIODS }
  validates :invitation_delivery_mode, inclusion: { in: INVITATION_DELIVERY_MODES }
  validates :billing_cycle, inclusion: { in: BILLING_CYCLES }
  validates :default_teacher_rate, :default_lesson_price,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1_000_000 }

  validates :default_lesson_duration_minutes, numericality: { only_integer: true, in: 1..480 }
  validates :minimum_lesson_duration_minutes, :maximum_lesson_duration_minutes,
            :lesson_duration_step_minutes, numericality: { only_integer: true, in: 1..480 }
  validates :minimum_booking_notice_hours, :reschedule_notice_hours,
            :student_cancellation_notice_hours, :teacher_cancellation_notice_hours,
            :late_cancellation_window_hours, :lesson_reminder_hours_before,
            numericality: { only_integer: true, in: 0..8_760 }
  validates :maximum_booking_window_days, numericality: { only_integer: true, in: 0..730 }
  validates :invitation_expires_after_hours, numericality: { only_integer: true, in: 1..8_760 }
  validates :student_late_after_minutes, :teacher_late_after_minutes, :absence_after_minutes,
            :second_lesson_reminder_minutes_before, :teacher_check_in_opens_minutes_before,
            :teacher_check_in_closes_minutes_after, :left_early_threshold_minutes,
            numericality: { only_integer: true, in: 0..1_440 }
  validates :lesson_reminder_minutes_before, :first_late_reminder_minutes, :second_late_reminder_minutes,
            numericality: { only_integer: true, in: 0..1_440 }
  validate :validate_notification_reminders

  validate :validate_collections
  validate :validate_locale_relationship
  validate :validate_operating_hours
  validate :validate_lesson_durations
  validate :validate_cancellation_rules
  validate :validate_attendance_rules
  validate :validate_assessment_grade_boundaries

  before_validation :normalize_values

  def self.current
    find_or_create_by!(singleton_key: SINGLETON_KEY)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def self.current_or_nil
    find_by(singleton_key: SINGLETON_KEY)
  rescue ActiveRecord::StatementInvalid
    nil
  end

  private

  def normalize_values
    normalize_contact_email
    normalize_region_codes
    normalize_collection_values
  end

  def normalize_contact_email
    self.contact_email = contact_email.to_s.strip.downcase.presence
  end

  def normalize_region_codes
    self.country_code = country_code.to_s.upcase
    self.payroll_currency = payroll_currency.to_s.upcase
    self.billing_currency = billing_currency.to_s.upcase
  end

  def normalize_collection_values
    self.supported_locales = normalized_array(supported_locales, INTERFACE_LOCALES)
    self.teaching_languages = normalized_array(teaching_languages, TEACHING_LANGUAGES)
    self.working_days = normalized_array(working_days, WEEKDAYS)
  end

  def normalized_array(values, order)
    Array(values).compact_blank.map(&:to_s).uniq.sort_by { |value| order.index(value) || order.length }
  end

  def validate_collections
    validate_collection(:supported_locales, INTERFACE_LOCALES)
    validate_collection(:teaching_languages, TEACHING_LANGUAGES)
    validate_collection(:working_days, WEEKDAYS)
  end

  def validate_collection(attribute, allowlist)
    values = public_send(attribute)
    errors.add(attribute, :blank) if values.empty?
    errors.add(attribute, :invalid) unless (values - allowlist).empty?
  end

  def validate_locale_relationship
    errors.add(:default_locale, :not_supported) unless default_locale.in?(supported_locales)
  end

  def validate_operating_hours
    return if day_starts_at.blank? || day_ends_at.blank? || day_starts_at < day_ends_at

    errors.add(:day_ends_at, :after_start)
  end

  def validate_lesson_durations
    return unless [minimum_lesson_duration_minutes, default_lesson_duration_minutes,
                   maximum_lesson_duration_minutes, lesson_duration_step_minutes].all?

    errors.add(:default_lesson_duration_minutes, :outside_range) unless duration_in_range?
    return if duration_aligned_to_step?

    errors.add(:lesson_duration_step_minutes, :misaligned)
  end

  def duration_in_range?
    default_lesson_duration_minutes.between?(
      minimum_lesson_duration_minutes, maximum_lesson_duration_minutes
    )
  end

  def duration_aligned_to_step?
    lesson_duration_step_minutes.positive? &&
      ((default_lesson_duration_minutes - minimum_lesson_duration_minutes) % lesson_duration_step_minutes).zero?
  end

  def validate_cancellation_rules
    limit = [student_cancellation_notice_hours, teacher_cancellation_notice_hours].compact.min
    errors.add(:late_cancellation_window_hours, :too_large) if limit && late_cancellation_window_hours.to_i > limit
  end

  def validate_attendance_rules
    threshold = [student_late_after_minutes, teacher_late_after_minutes].compact.max
    errors.add(:absence_after_minutes, :too_small) if threshold && absence_after_minutes.to_i < threshold
  end

  def validate_notification_reminders
    return if first_late_reminder_minutes.to_i < second_late_reminder_minutes.to_i

    errors.add(:second_late_reminder_minutes, :after_first_reminder)
  end

  def validate_assessment_grade_boundaries
    boundaries = assessment_grade_boundaries.to_h
    expected = StudentAssessment::LETTER_GRADES
    errors.add(:assessment_grade_boundaries, :invalid) unless boundaries.keys.sort == expected.sort
    values = expected.filter_map { |grade| decimal_boundary(boundaries[grade]) }
    invalid_values = values.size != expected.size || values.any? { |value| !value.in?(0..100) }
    errors.add(:assessment_grade_boundaries, :invalid) if invalid_values || values != values.sort.reverse
  end

  def decimal_boundary(value)
    BigDecimal(value.to_s)
  rescue ArgumentError
    nil
  end
end
