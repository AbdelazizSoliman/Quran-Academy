class TeacherProfile < ApplicationRecord
  GENDERS = %w[male female unspecified].freeze
  EMPLOYMENT_STATUSES = %w[candidate active on_leave inactive departed].freeze
  ENGAGEMENT_TYPES = %w[contractor part_time full_time volunteer].freeze
  PROFILE_STATUSES = %w[draft complete verified archived].freeze
  COMPENSATION_UNITS = %w[per_lesson per_hour monthly].freeze
  IJAZAH_STATUSES = %w[none in_progress partial full multiple].freeze
  AGE_GROUPS = %w[children teenagers adults seniors].freeze
  SPECIALIZATIONS = %w[quran_reading quran_memorization tajweed arabic_language islamic_studies qaida_noorania
                       revision recitation_correction new_muslim_foundations].freeze
  ARRAY_CATALOGS = {
    teaching_languages: lambda {
      AcademySetting.current_or_nil&.teaching_languages.presence || AcademySetting::TEACHING_LANGUAGES
    },
    student_age_groups: -> { AGE_GROUPS },
    teaching_specializations: -> { SPECIALIZATIONS }
  }.freeze
  COMPLETENESS_FIELDS = %i[display_name bio contact country_of_residence teaching_languages teaching_specializations
                           student_age_groups experience employment_status compensation].freeze

  belongs_to :user, inverse_of: :teacher_profile
  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_teacher_profiles
  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_teacher_profiles
  has_many :events, class_name: "TeacherProfileEvent", dependent: :restrict_with_exception
  has_many :availabilities, class_name: "TeacherAvailability", dependent: :restrict_with_exception
  has_many :availability_exceptions, class_name: "TeacherAvailabilityException", dependent: :restrict_with_exception
  has_many :scheduled_lessons, inverse_of: :teacher_profile, dependent: :restrict_with_exception
  has_many :lesson_reports, dependent: :restrict_with_exception

  attr_readonly :public_id

  before_validation :normalize_values
  before_validation :apply_academy_defaults, on: :create
  before_validation :generate_public_id, on: :create

  validates :user_id, uniqueness: true
  validates :public_id, presence: true, uniqueness: true, format: { with: /\ATCH-[A-Z0-9]{10}\z/ }
  validates :gender, inclusion: { in: GENDERS }
  validates :employment_status, inclusion: { in: EMPLOYMENT_STATUSES }
  validates :engagement_type, inclusion: { in: ENGAGEMENT_TYPES }
  validates :profile_status, inclusion: { in: PROFILE_STATUSES }
  validates :compensation_unit, inclusion: { in: COMPENSATION_UNITS }
  validates :ijazah_status, inclusion: { in: IJAZAH_STATUSES }
  validates :compensation_currency, format: { with: AcademySetting::CURRENCY_PATTERN }
  validates :default_lesson_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1_000_000 }
  validates :years_of_teaching_experience, :quran_teaching_experience_years,
            numericality: { only_integer: true, in: 0..100 }
  validates :display_name, :nationality, :country_of_residence, :city,
            :highest_qualification, :tajweed_qualification, length: { maximum: 150 }, allow_blank: true
  validates :phone_number, :whatsapp_number, :emergency_contact_phone,
            length: { maximum: 30 }, allow_blank: true
  validates :bio, :qualification_details, :ijazah_details, :internal_notes,
            length: { maximum: 5_000 }, allow_blank: true

  validate :user_has_teacher_role
  validate :validate_catalogs
  validate :validate_experience
  validate :validate_date_order
  validate :validate_departure_date
  validate :validate_active_date
  validate :validate_complete_profile, if: :complete_or_verified?

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
  scope :available_for_scheduling, -> { where(employment_status: "active").where.not(profile_status: "archived") }

  def completion_percentage
    completed = COMPLETENESS_FIELDS.count { |field| completeness_value?(field) }
    ((completed.to_f / COMPLETENESS_FIELDS.length) * 100).round
  end

  def missing_required_fields
    COMPLETENESS_FIELDS.reject { |field| completeness_value?(field) }
  end

  def complete?
    missing_required_fields.empty?
  end

  def archived?
    profile_status == "archived"
  end

  private

  def normalize_values
    self.compensation_currency = compensation_currency.to_s.upcase
    normalize_phone_numbers
    normalize_catalog_arrays
  end

  def normalize_phone_numbers
    %i[phone_number whatsapp_number emergency_contact_phone].each do |attribute|
      self[attribute] = self[attribute].to_s.strip.presence
    end
  end

  def normalize_catalog_arrays
    ARRAY_CATALOGS.each_key { |attribute| self[attribute] = Array(self[attribute]).compact_blank.map(&:to_s).uniq }
  end

  def generate_public_id
    self.public_id ||= "TCH-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def apply_academy_defaults
    setting = AcademySetting.current_or_nil
    return unless setting

    apply_language_default(setting)
    apply_compensation_defaults(setting)
  end

  def apply_language_default(setting)
    self.teaching_languages = setting.teaching_languages.first(1) if teaching_languages.empty?
  end

  def apply_compensation_defaults(setting)
    self.default_lesson_rate ||= setting.default_teacher_rate
    self.compensation_currency = setting.payroll_currency if compensation_currency.blank?
    self.compensation_unit = setting.default_teacher_compensation_type if compensation_unit.blank?
  end

  def user_has_teacher_role
    errors.add(:user, :must_be_teacher) unless user&.teacher?
  end

  def validate_catalogs
    ARRAY_CATALOGS.each do |attribute, catalog|
      errors.add(attribute, :invalid) if (public_send(attribute) - catalog.call).any?
    end
  end

  def validate_experience
    return if quran_teaching_experience_years.to_i <= years_of_teaching_experience.to_i

    errors.add(:quran_teaching_experience_years, :greater_than_total)
  end

  def validate_date_order
    errors.add(:left_on, :before_joined_on) if left_on && joined_on && left_on < joined_on
  end

  def validate_departure_date
    errors.add(:left_on, :required_for_departed) if employment_status == "departed" && left_on.blank?
  end

  def validate_active_date
    errors.add(:left_on, :not_allowed_for_active) if employment_status == "active" && left_on&.<(Date.current)
  end

  def complete_or_verified?
    profile_status.in?(%w[complete verified])
  end

  def validate_complete_profile
    validation_fields = {
      contact: :phone_number, experience: :years_of_teaching_experience,
      compensation: :default_lesson_rate
    }
    missing_required_fields.each { |field| errors.add(validation_fields.fetch(field, field), :required_for_complete) }
  end

  def completeness_value?(field)
    case field
    when :contact then phone_number.present? || whatsapp_number.present?
    when :experience then years_of_teaching_experience.present?
    when :compensation then default_lesson_rate.present? && compensation_currency.present? && compensation_unit.present?
    else public_send(field).present?
    end
  end
end
