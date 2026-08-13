class CourseOffering < ApplicationRecord
  STATUSES = %w[draft open closed in_progress completed cancelled archived].freeze
  DELIVERY_MODES = %w[online in_person hybrid].freeze
  CAPACITY_STATUSES = %w[approved active paused].freeze

  belongs_to :program
  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_course_offerings
  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_course_offerings
  has_many :enrollments, dependent: :restrict_with_exception
  has_many :course_offering_teachers, inverse_of: :course_offering, dependent: :restrict_with_exception
  has_many :teacher_profiles, through: :course_offering_teachers
  has_many :events, class_name: "CourseOfferingEvent", dependent: :restrict_with_exception
  has_many :scheduled_lessons, dependent: :restrict_with_exception
  has_many :exam_sessions, dependent: :restrict_with_exception

  attr_readonly :public_id
  before_validation :normalize_values
  before_validation :apply_program_defaults, on: :create
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AOFR-[A-Z0-9]{10}\z/ }
  validates :code, presence: true, uniqueness: { case_sensitive: false }, format: { with: Program::CODE_PATTERN }
  validates :title_ar, :title_en, presence: true, length: { maximum: 200 }
  validates :status, inclusion: { in: STATUSES }
  validates :delivery_mode, inclusion: { in: DELIVERY_MODES }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :intended_lessons_per_week, numericality: { only_integer: true, in: 1..14 }
  validates :internal_notes, length: { maximum: 5_000 }, allow_blank: true
  validate :program_compatibility
  validate :date_order
  validate :duration_rules
  validate :status_consistency
  validate :protect_code_and_program

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def capacity_used
    enrollments.where(status: CAPACITY_STATUSES).count
  end

  def capacity_available
    capacity && [capacity - capacity_used, 0].max
  end

  def full?
    capacity.present? && capacity_used >= capacity
  end

  def archived? = status == "archived"
  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  private

  def normalize_values
    self.code = code.to_s.strip.upcase
    self.learning_language = learning_language.to_s.downcase
    self.target_age_groups = Array(target_age_groups).compact_blank.map(&:to_s).uniq
  end

  def apply_program_defaults
    return unless program

    copy_program_defaults
    self.placement_required = program.requires_placement unless placement_required || @placement_required_explicit
  end

  # The default snapshot intentionally assigns several independent operational values.
  # rubocop:disable Metrics/AbcSize
  def copy_program_defaults
    self.learning_language = program.default_learning_language if learning_language.blank?
    self.target_age_groups = program.target_age_groups if target_age_groups.empty?
    self.default_lesson_duration_minutes ||= program.default_lesson_duration_minutes
    self.intended_lessons_per_week ||= program.recommended_lessons_per_week
  end

  def generate_public_id
    self.public_id ||= "OFR-#{SecureRandom.alphanumeric(10).upcase}"
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def program_compatibility
    return unless program

    errors.add(:program, :archived) if new_record? && program.archived?
    unless program.supported_learning_languages.include?(learning_language)
      errors.add(:learning_language,
                 :not_supported)
    end
    errors.add(:target_age_groups, :invalid) if target_age_groups.empty? ||
                                                (target_age_groups - program.target_age_groups).any?
    errors.add(:program, :must_be_active_for_open) if status == "open" && !program.active?
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def date_order
    errors.add(:enrollment_closes_on, :before_opens) if enrollment_opens_on && enrollment_closes_on &&
                                                        enrollment_closes_on < enrollment_opens_on
    errors.add(:planned_end_on, :before_start) if planned_start_on && planned_end_on &&
                                                  planned_end_on < planned_start_on
    errors.add(:enrollment_closes_on, :after_planned_end) if enrollment_closes_on && planned_end_on &&
                                                             enrollment_closes_on > planned_end_on
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def duration_rules
    return unless program

    setting = AcademySetting.current_or_nil
    return unless setting

    range = setting.minimum_lesson_duration_minutes..setting.maximum_lesson_duration_minutes
    errors.add(:default_lesson_duration_minutes, :outside_range) unless range.cover?(default_lesson_duration_minutes)
  end

  def status_consistency
    errors.add(:accepts_new_enrollments, :required_for_open) if status == "open" && !accepts_new_enrollments?
    errors.add(:accepts_new_enrollments, :not_allowed) if status.in?(%w[closed in_progress completed cancelled
                                                                        archived]) &&
                                                          accepts_new_enrollments?
    errors.add(:planned_end_on, :required_for_completed) if status == "completed" && planned_end_on.blank?
  end

  def protect_code_and_program
    return unless persisted? && enrollments.exists?

    errors.add(:code, :operational_history) if will_save_change_to_code?
    errors.add(:program, :operational_history) if will_save_change_to_program_id?
  end
end
