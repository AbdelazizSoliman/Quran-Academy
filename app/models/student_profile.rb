class StudentProfile < ApplicationRecord
  GENDERS = %w[male female unspecified].freeze
  STUDENT_TYPES = %w[adult minor child].freeze
  PROFILE_STATUSES = %w[draft complete verified archived].freeze
  # "at_risk" and "inactive" are the two Madarak-vocabulary values with no clean prior QA
  # equivalent; added additively (nothing renamed/removed) to avoid a data migration while still
  # letting the create form's status select match Madarak exactly. A full vocabulary reconciliation
  # remains a separate, larger decision (see docs/madarak-implementation-plan.md Task 3).
  LEARNING_STATUSES = %w[prospective trial active paused completed departed at_risk inactive].freeze
  CONTACT_METHODS = %w[email phone whatsapp guardian].freeze
  INTERFACE_LOCALES = %w[ar en].freeze
  LEARNING_LANGUAGES = %w[ar en].freeze
  QURAN_LEVELS = %w[beginner elementary intermediate advanced].freeze
  READING_LEVELS = %w[not_started letters words sentences fluent].freeze
  TAJWEED_LEVELS = %w[none basic intermediate advanced].freeze
  MEMORIZATION_LEVELS = %w[none short_surahs juz_amma multiple_ajzaa advanced].freeze
  SESSION_TYPES = %w[individual group].freeze
  DELIVERY_METHODS = %w[email whatsapp both].freeze
  CURRENCIES = %w[EGP USD EUR GBP SAR AED].freeze
  WEEKDAYS = %w[sunday monday tuesday wednesday thursday friday saturday].freeze
  LESSON_SUBJECTS = %w[memorization tajweed revision general].freeze
  # Exact list, order, flags, and Arabic names as rendered by the real Madarak "New Student" page
  # (source: user-provided rendered DOM HTML, 2026-08-12) — not the app's own prior approximation.
  COUNTRY_DIAL_CODES = {
    "EG" => ["🇪🇬", "مصر", "20"], "SA" => ["🇸🇦", "السعودية", "966"], "AE" => ["🇦🇪", "الإمارات", "971"],
    "KW" => ["🇰🇼", "الكويت", "965"], "QA" => ["🇶🇦", "قطر", "974"], "BH" => ["🇧🇭", "البحرين", "973"],
    "OM" => ["🇴🇲", "عُمان", "968"], "JO" => ["🇯🇴", "الأردن", "962"], "PS" => ["🇵🇸", "فلسطين", "970"],
    "LB" => ["🇱🇧", "لبنان", "961"], "SY" => ["🇸🇾", "سوريا", "963"], "IQ" => ["🇮🇶", "العراق", "964"],
    "YE" => ["🇾🇪", "اليمن", "967"], "SD" => ["🇸🇩", "السودان", "249"], "LY" => ["🇱🇾", "ليبيا", "218"],
    "TN" => ["🇹🇳", "تونس", "216"], "DZ" => ["🇩🇿", "الجزائر", "213"], "MA" => ["🇲🇦", "المغرب", "212"],
    "MR" => ["🇲🇷", "موريتانيا", "222"], "SO" => ["🇸🇴", "الصومال", "252"], "DJ" => ["🇩🇯", "جيبوتي", "253"],
    "TR" => ["🇹🇷", "تركيا", "90"], "US" => ["🇺🇸", "الولايات المتحدة", "1"], "GB" => ["🇬🇧", "بريطانيا", "44"],
    "CA" => ["🇨🇦", "كندا", "1"], "DE" => ["🇩🇪", "ألمانيا", "49"], "FR" => ["🇫🇷", "فرنسا", "33"],
    "NL" => ["🇳🇱", "هولندا", "31"], "SE" => ["🇸🇪", "السويد", "46"], "MY" => ["🇲🇾", "ماليزيا", "60"],
    "ID" => ["🇮🇩", "إندونيسيا", "62"], "PK" => ["🇵🇰", "باكستان", "92"]
  }.freeze
  COUNTRIES = COUNTRY_DIAL_CODES.transform_values { |(flag, name, _dial)| "#{flag} #{name}" }.freeze
  PHONE_COUNTRY_CODES = COUNTRY_DIAL_CODES.transform_values { |(flag, name, dial)| ["#{flag} #{name}", dial] }.freeze
  SENSITIVE_FIELDS = %w[
    medical_notes safeguarding_notes special_learning_needs internal_notes
    emergency_contact_name emergency_contact_phone guardian_name guardian_phone guardian_email
  ].freeze

  belongs_to :user, inverse_of: :student_profile
  belongs_to :assigned_teacher_profile, class_name: "TeacherProfile", optional: true,
                                        inverse_of: :assigned_students
  belongs_to :sibling_student_profile, class_name: "StudentProfile", optional: true
  belongs_to :fee_plan, optional: true, inverse_of: :student_profiles
  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_student_profiles
  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_student_profiles

  has_many :enrollments, dependent: :restrict_with_exception
  has_many :course_offerings, through: :enrollments
  has_many :direct_scheduled_lesson_enrollments, class_name: "ScheduledLessonEnrollment",
                                                 dependent: :restrict_with_exception, inverse_of: :student_profile
  has_many :direct_lesson_schedules, class_name: "EnrollmentLessonSchedule",
                                     dependent: :restrict_with_exception, inverse_of: :student_profile
  has_many :student_guardianships, dependent: :restrict_with_exception
  has_many :guardians, through: :student_guardianships
  has_many :events, class_name: "StudentProfileEvent", inverse_of: :student_profile,
                    dependent: :restrict_with_exception
  has_many :student_assessments, dependent: :restrict_with_exception
  has_one :student_progress, dependent: :restrict_with_exception
  has_many :certificates, dependent: :restrict_with_exception

  attr_readonly :public_id, :user_id

  before_validation :normalize_values
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\ASTD-[A-Z0-9]{1,20}\z/ }
  validates :user_id, uniqueness: true
  validates :gender, inclusion: { in: GENDERS }
  validates :student_type, inclusion: { in: STUDENT_TYPES }
  validates :profile_status, inclusion: { in: PROFILE_STATUSES }
  validates :learning_status, inclusion: { in: LEARNING_STATUSES }
  validates :preferred_contact_method, inclusion: { in: CONTACT_METHODS }
  validates :preferred_interface_locale, inclusion: { in: INTERFACE_LOCALES }
  validates :preferred_learning_language, inclusion: { in: LEARNING_LANGUAGES }, allow_blank: true
  validates :current_quran_level, inclusion: { in: QURAN_LEVELS }
  validates :reading_level, inclusion: { in: READING_LEVELS }
  validates :tajweed_level, inclusion: { in: TAJWEED_LEVELS }
  validates :memorization_level, inclusion: { in: MEMORIZATION_LEVELS }
  validates :session_type, inclusion: { in: SESSION_TYPES }
  validates :account_delivery_method, inclusion: { in: DELIVERY_METHODS }
  validates :billing_currency, inclusion: { in: CURRENCIES }
  validates :schedule_weekday, inclusion: { in: WEEKDAYS }, allow_blank: true
  validates :memorized_juz_count, numericality: { only_integer: true, in: 0..30 }, allow_nil: true
  validates :attendance_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :schedule_generation_weeks, numericality: { only_integer: true, in: 1..48 }, allow_nil: true
  validates :prior_sessions_taken, :remaining_sessions_at_onboarding,
            numericality: { only_integer: true, in: 0..500 }, allow_nil: true
  validates :discount_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :wallet_balance, :weekly_price, numericality: { greater_than_or_equal_to: 0 }
  validates :weekly_lesson_count, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :sessions_per_month, numericality: { only_integer: true, in: 1..672 }, allow_nil: true
  validates :lesson_duration_minutes, numericality: { only_integer: true, in: 15..120 }, allow_nil: true
  validates :phone_number, :whatsapp_number, :guardian_phone, :emergency_contact_phone,
            length: { maximum: 30 }, allow_blank: true
  validates :guardian_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :user_must_be_student
  validate :lifecycle_date_order
  validate :verified_profile_readiness

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  PROFILE_STATUSES.each { |value| define_method(:"#{value}?") { profile_status == value } }
  LEARNING_STATUSES.each { |value| define_method(:"#{value}?") { learning_status == value } }

  def age(reference_date = Date.current)
    return if date_of_birth.blank?

    years = reference_date.year - date_of_birth.year
    years -= 1 if reference_date < date_of_birth.advance(years: years)
    years
  end

  def minor?
    student_type.in?(%w[minor child])
  end

  def age_type_mismatch?
    return false if age.nil?

    (age < 18) != minor?
  end

  def active_guardianships
    student_guardianships.active
  end

  # Participation spans both scheduling paths: enrollment-backed (Program -> CourseOffering ->
  # Enrollment) and direct (fee-plan-only students attached straight to a ScheduledLessonEnrollment).
  # A plain has_many :through can only follow one path, so this reuses the shared resolver scope.
  def scheduled_lesson_enrollments
    ScheduledLessonEnrollment.for_student_profile_ids(id)
  end

  def scheduled_lessons
    ScheduledLesson.where(id: scheduled_lesson_enrollments.select(:scheduled_lesson_id)).distinct
  end

  def guardian_requirements_met?
    active_guardianships.any? { |link| link.primary_contact? && link.emergency_contact? && link.legal_guardian? }
  end

  def missing_required_fields
    fields = %i[display_name gender country_of_residence preferred_learning_language
                current_quran_level reading_level tajweed_level memorization_level learning_goals]
    fields.select { |field| public_send(field).blank? }
  end

  def completion_percentage
    missing_required_fields.length
    (missing_required_fields.empty? ? 1 : 0)
    return 100 if missing_required_fields.empty?

    required_count = 9
    (((required_count - missing_required_fields.length).to_f / required_count) * 100).round.clamp(0, 100)
  end

  def complete?
    missing_required_fields.empty?
  end

  private

  def normalize_values
    self.display_name = display_name.to_s.strip.presence
    self.preferred_interface_locale = preferred_interface_locale.to_s.downcase
    self.preferred_learning_language = preferred_learning_language.to_s.downcase.presence
    self.schedule_weekday = schedule_weekday.to_s.downcase.presence
    self.schedule_slots = Array(schedule_slots).filter_map do |slot|
      normalized = slot.respond_to?(:to_h) ? slot.to_h.stringify_keys : nil
      next if normalized.blank?

      normalized.compact_blank
    end
    %i[phone_number whatsapp_number guardian_phone emergency_contact_phone].each do |field|
      self[field] = self[field].to_s.strip.presence
    end
    self.guardian_email = guardian_email.to_s.strip.downcase.presence
  end

  def generate_public_id
    self.public_id = public_id.to_s.strip.upcase.presence || "STD-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def user_must_be_student
    errors.add(:user, :must_be_student) unless user&.student?
  end

  def lifecycle_date_order
    return if joined_on.blank? || left_on.blank? || left_on >= joined_on

    errors.add(:left_on, :after_joined_on)
  end

  def verified_profile_readiness
    return unless profile_status == "verified"

    missing_required_fields.each { |field| errors.add(field, :blank) }
    return unless minor?

    errors.add(:base, :guardian_required_for_minor) unless guardian_requirements_met?
  end
end
