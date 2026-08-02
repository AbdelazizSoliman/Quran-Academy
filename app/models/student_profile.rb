class StudentProfile < ApplicationRecord
  has_many :student_assessments, dependent: :restrict_with_exception
  has_one :student_progress, dependent: :restrict_with_exception
  has_many :certificates, dependent: :restrict_with_exception
  GENDERS = %w[male female unspecified].freeze
  STUDENT_TYPES = %w[minor adult].freeze
  PROFILE_STATUSES = %w[draft complete verified archived].freeze
  LEARNING_STATUSES = %w[prospective active paused inactive departed].freeze
  CONTACT_METHODS = %w[email phone whatsapp guardian].freeze
  QURAN_LEVELS = %w[beginner foundation reading intermediate advanced memorization revision].freeze
  READING_LEVELS = %w[not_started letters words sentences fluent advanced].freeze
  TAJWEED_LEVELS = %w[none basic intermediate advanced qualified].freeze
  MEMORIZATION_LEVELS = %w[none short_surahs partial_juz multiple_juz half_quran most_quran complete_quran
                           revision].freeze
  SENSITIVE_FIELDS = %w[medical_notes safeguarding_notes special_learning_needs internal_notes].freeze
  COMPLETENESS_FIELDS = %i[
    display_name student_type date_of_birth country_of_residence preferred_learning_language
    current_quran_level learning_goals learning_status contact
  ].freeze

  belongs_to :user, inverse_of: :student_profile
  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_student_profiles
  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_student_profiles
  has_many :student_guardianships, dependent: :restrict_with_exception
  has_many :guardians, through: :student_guardianships
  has_many :events, class_name: "StudentProfileEvent", dependent: :restrict_with_exception
  has_many :enrollments, dependent: :restrict_with_exception
  has_many :scheduled_lesson_enrollments,
           through: :enrollments

  has_many :scheduled_lessons,
           -> { distinct },
           through: :scheduled_lesson_enrollments
  has_many :course_offerings, through: :enrollments
  has_many :programs, through: :course_offerings
  has_many :communication_logs, dependent: :restrict_with_exception

  attr_readonly :public_id
  before_validation :normalize_values
  before_validation :apply_defaults, on: :create
  before_validation :generate_public_id, on: :create

  validates :user_id, uniqueness: true
  validates :public_id, presence: true, uniqueness: true, format: { with: /\ASTD-[A-Z0-9]{10}\z/ }
  validates :gender, inclusion: { in: GENDERS }
  validates :student_type, inclusion: { in: STUDENT_TYPES }
  validates :profile_status, inclusion: { in: PROFILE_STATUSES }
  validates :learning_status, inclusion: { in: LEARNING_STATUSES }
  validates :preferred_contact_method, inclusion: { in: CONTACT_METHODS }
  validates :preferred_interface_locale, inclusion: { in: ->(_) { I18n.available_locales.map(&:to_s) } }
  validates :current_quran_level, inclusion: { in: QURAN_LEVELS }
  validates :reading_level, inclusion: { in: READING_LEVELS }
  validates :tajweed_level, inclusion: { in: TAJWEED_LEVELS }
  validates :memorization_level, inclusion: { in: MEMORIZATION_LEVELS }
  validates :memorized_juz_count, numericality: { only_integer: true, in: 0..30 }, allow_nil: true
  validates :display_name, :nationality, :country_of_residence, :city, length: { maximum: 150 }, allow_blank: true
  validates :phone_number, :whatsapp_number, :emergency_contact_phone, length: { maximum: 30 }, allow_blank: true
  validates :learning_goals, :learning_notes, :special_learning_needs, :medical_notes,
            :safeguarding_notes, :internal_notes, length: { maximum: 5_000 }, allow_blank: true

  validate :user_has_student_role
  validate :supported_learning_language
  validate :date_order
  validate :departure_rules
  validate :age_type_consistency, if: :complete_or_verified?
  validate :complete_profile_requirements, if: :complete_or_verified?
  validate :verified_guardian_requirements, if: :verified_minor?

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def age(on: Date.current)
    return unless date_of_birth

    birthday_passed = ((on.month * 100) + on.day) >= ((date_of_birth.month * 100) + date_of_birth.day)
    on.year - date_of_birth.year - (birthday_passed ? 0 : 1)
  end

  def minor_by_age?
    age&.<(18)
  end

  def age_type_mismatch?
    age && (minor? != minor_by_age?)
  end

  def minor?
    student_type == "minor"
  end

  def archived?
    profile_status == "archived"
  end

  def active_guardianships
    student_guardianships.select(&:active?)
  end

  def guardian_requirements_met?
    links = active_guardianships
    links.one?(&:primary_contact?) &&
      links.any? { |link| link.guardian.usable_contact? } &&
      links.any? { |link| link.legal_guardian? || link.can_make_academic_decisions? } &&
      links.any?(&:emergency_contact?)
  end

  def missing_required_fields
    missing = COMPLETENESS_FIELDS.reject { |field| completeness_value?(field) }
    missing << :guardian_requirements if minor? && !guardian_requirements_met?
    missing
  end

  def completion_percentage
    fields = COMPLETENESS_FIELDS + (minor? ? [:guardian_requirements] : [])
    completed = fields.count do |field|
      field == :guardian_requirements ? guardian_requirements_met? : completeness_value?(field)
    end
    ((completed.to_f / fields.size) * 100).round
  end

  def complete?
    missing_required_fields.empty?
  end

  private

  def normalize_values
    %i[phone_number whatsapp_number emergency_contact_phone].each do |field|
      self[field] = self[field].to_s.strip.presence
    end
    self.preferred_learning_language = preferred_learning_language.to_s.downcase.presence
    self.preferred_interface_locale = preferred_interface_locale.to_s.downcase
  end

  def apply_defaults
    setting = AcademySetting.current_or_nil
    self.preferred_interface_locale = user&.preferred_locale.presence || setting&.default_locale || "ar"
    self.preferred_learning_language ||= setting&.teaching_languages&.first
    self.display_name ||= user&.full_name
    self.joined_on ||= Date.current
    self.preferred_contact_method = minor? ? "guardian" : "email" if preferred_contact_method.blank?
  end

  def generate_public_id
    self.public_id ||= "STD-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def user_has_student_role
    errors.add(:user, :must_be_student) unless user&.student?
  end

  def supported_learning_language
    catalog = AcademySetting.current_or_nil&.teaching_languages.presence || AcademySetting::TEACHING_LANGUAGES
    return unless preferred_learning_language.present? && catalog.exclude?(preferred_learning_language)

    errors.add(:preferred_learning_language,
               :invalid)
  end

  def date_order
    errors.add(:left_on, :before_joined_on) if left_on && joined_on && left_on < joined_on
  end

  def departure_rules
    errors.add(:left_on, :required_for_departed) if learning_status == "departed" && left_on.blank?
    errors.add(:left_on, :not_allowed_for_active) if learning_status == "active" && left_on&.<(Date.current)
  end

  def complete_or_verified?
    profile_status.in?(%w[complete verified])
  end

  def verified_minor?
    profile_status == "verified" && minor?
  end

  def age_type_consistency
    errors.add(:student_type, :age_mismatch) if age_type_mismatch?
  end

  def complete_profile_requirements
    missing_required_fields.each do |field|
      errors.add(field == :contact ? :preferred_contact_method : field, :required_for_complete)
    end
  end

  def verified_guardian_requirements
    errors.add(:student_guardianships, :requirements_not_met) unless guardian_requirements_met?
  end

  def completeness_value?(field)
    case field
    when :contact
      user&.email.present? || phone_number.present? || whatsapp_number.present? || (minor? && active_guardianships.any?)
    else public_send(field).present?
    end
  end
end
