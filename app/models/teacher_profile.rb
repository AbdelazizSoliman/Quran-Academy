class TeacherProfile < ApplicationRecord
  GENDERS = %w[male female unspecified].freeze
  EMPLOYMENT_STATUSES = %w[candidate active inactive suspended departed].freeze
  ENGAGEMENT_TYPES = %w[employee contractor volunteer].freeze
  PROFILE_STATUSES = %w[draft complete verified archived].freeze
  IJAZAH_STATUSES = %w[none partial full].freeze
  COMPENSATION_UNITS = %w[per_lesson hourly monthly].freeze
  CURRENCIES = %w[EGP USD EUR GBP SAR AED].freeze
  NOTIFICATION_METHODS = %w[email whatsapp both].freeze
  MESSAGE_LANGUAGES = %w[ar en].freeze
  WORK_DAYS = %w[sunday monday tuesday wednesday thursday friday saturday].freeze
  AGE_GROUPS = %w[children teenagers adults seniors].freeze
  SPECIALIZATIONS = %w[quran_reading tajweed memorization arabic islamic_studies].freeze

  belongs_to :user, inverse_of: :teacher_profile
  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_teacher_profiles
  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_teacher_profiles

  has_many :availabilities, class_name: "TeacherAvailability", inverse_of: :teacher_profile,
                            dependent: :restrict_with_exception
  has_many :availability_exceptions, class_name: "TeacherAvailabilityException",
                                     inverse_of: :teacher_profile, dependent: :restrict_with_exception
  has_many :scheduled_lessons, dependent: :restrict_with_exception
  has_many :lesson_reports, inverse_of: :teacher_profile, dependent: :restrict_with_exception
  has_many :course_offering_teachers, inverse_of: :teacher_profile, dependent: :restrict_with_exception
  has_many :course_offerings, through: :course_offering_teachers
  has_many :enrollment_lesson_schedules, dependent: :restrict_with_exception
  has_many :assigned_students, class_name: "StudentProfile", foreign_key: :assigned_teacher_profile_id,
                               inverse_of: :assigned_teacher_profile, dependent: :nullify
  has_many :events, class_name: "TeacherProfileEvent", inverse_of: :teacher_profile,
                    dependent: :restrict_with_exception
  has_many :teacher_payrolls, dependent: :restrict_with_exception

  attr_readonly :public_id, :user_id

  before_validation :apply_academy_defaults, on: :create
  before_validation :normalize_values
  before_validation :normalize_online_meeting_url
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\ATCH-[A-Z0-9]{10}\z/ }
  validates :user_id, uniqueness: true
  validates :gender, inclusion: { in: GENDERS }
  validates :employment_status, inclusion: { in: EMPLOYMENT_STATUSES }
  validates :engagement_type, inclusion: { in: ENGAGEMENT_TYPES }
  validates :profile_status, inclusion: { in: PROFILE_STATUSES }
  validates :ijazah_status, inclusion: { in: IJAZAH_STATUSES }
  validates :compensation_unit, inclusion: { in: COMPENSATION_UNITS }
  validates :compensation_currency, inclusion: { in: CURRENCIES }
  validates :notification_method, inclusion: { in: NOTIFICATION_METHODS }
  validates :message_language, inclusion: { in: MESSAGE_LANGUAGES }
  validates :workload_percentage, numericality: { only_integer: true, in: 0..100 }
  validates :years_of_teaching_experience, :quran_teaching_experience_years,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :default_lesson_rate, :monthly_salary, numericality: { greater_than_or_equal_to: 0 }
  validates :phone_number, :whatsapp_number, :emergency_contact_phone,
            length: { maximum: 30 }, allow_blank: true
  validate :online_meeting_url_format
  validate :user_must_be_teacher
  validate :controlled_arrays
  validate :quran_experience_not_above_total
  validate :lifecycle_date_order
  validate :departed_requires_left_on
  validate :work_time_order
  validate :complete_profile_readiness

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
  scope :available_for_scheduling, -> { where(employment_status: "active").where.not(profile_status: "archived") }

  PROFILE_STATUSES.each { |value| define_method(:"#{value}?") { profile_status == value } }
  EMPLOYMENT_STATUSES.each { |value| define_method(:"#{value}?") { employment_status == value } }

  def missing_required_fields
    fields = %i[display_name bio country_of_residence phone_number highest_qualification
                qualification_details teaching_languages student_age_groups teaching_specializations]
    fields.select { |field| public_send(field).blank? }
  end

  def completion_percentage
    required_count = 9
    (((required_count - missing_required_fields.length).to_f / required_count) * 100).round.clamp(0, 100)
  end

  def complete?
    missing_required_fields.empty?
  end

  def safe_online_meeting_url = OnlineMeetingUrl.safe(online_meeting_url)

  private

  def normalize_online_meeting_url
    self.online_meeting_url = OnlineMeetingUrl.normalize(online_meeting_url) if online_meeting_url.present?
  end

  def online_meeting_url_format
    return if online_meeting_url.blank? || OnlineMeetingUrl.valid?(online_meeting_url)

    errors.add(:online_meeting_url, :invalid_url)
  end

  def apply_academy_defaults
    settings = AcademySetting.current
    self.teaching_languages = settings.teaching_languages if teaching_languages.blank?
    self.default_lesson_rate = settings.default_teacher_rate if default_lesson_rate.nil?
    self.compensation_currency = settings.payroll_currency if compensation_currency.blank?
    self.compensation_unit = settings.default_teacher_compensation_type if compensation_unit.blank?
  rescue StandardError
    nil
  end

  def normalize_values
    self.display_name = display_name.to_s.strip.presence
    %i[phone_number whatsapp_number emergency_contact_phone].each do |field|
      self[field] = self[field].to_s.strip.presence
    end
    self.teaching_languages = normalized_array(teaching_languages)
    self.student_age_groups = normalized_array(student_age_groups)
    self.teaching_specializations = normalized_array(teaching_specializations)
    self.work_days = normalized_array(work_days)
    self.message_language = message_language.to_s.downcase
  end

  def normalized_array(value)
    Array(value).map { |item| item.to_s.strip.downcase }.reject(&:blank?).uniq
  end

  def generate_public_id
    self.public_id ||= "TCH-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def user_must_be_teacher
    errors.add(:user, :must_be_teacher) unless user&.teacher?
  end

  def controlled_arrays
    validate_array_values(:teaching_languages, Array(AcademySetting.current.teaching_languages))
    validate_array_values(:student_age_groups, AGE_GROUPS)
    validate_array_values(:teaching_specializations, SPECIALIZATIONS)
    validate_array_values(:work_days, WORK_DAYS)
  end

  def validate_array_values(attribute, allowed)
    errors.add(attribute, :invalid) unless Array(public_send(attribute)).all? { |value| allowed.include?(value) }
  end

  def quran_experience_not_above_total
    return if quran_teaching_experience_years <= years_of_teaching_experience

    errors.add(:quran_teaching_experience_years, :less_than_or_equal_to_total)
  end

  def lifecycle_date_order
    return if joined_on.blank? || left_on.blank? || left_on >= joined_on

    errors.add(:left_on, :after_joined_on)
  end

  def departed_requires_left_on
    errors.add(:left_on, :blank) if employment_status == "departed" && left_on.blank?
  end

  # Optional together: a blank pair means "available all day" on the selected work days.
  def work_time_order
    return if work_start_time.blank? && work_end_time.blank?
    return errors.add(missing_work_time_field, :work_time_required) if [work_start_time, work_end_time].any?(&:blank?)

    errors.add(:work_end_time, :after_start) unless work_end_time > work_start_time
  end

  def missing_work_time_field = work_start_time.blank? ? :work_start_time : :work_end_time

  def complete_profile_readiness
    return unless profile_status.in?(%w[complete verified])

    missing_required_fields.each { |field| errors.add(field, :blank) }
  end
end
