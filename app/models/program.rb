class Program < ApplicationRecord
  include PubliclyPublishable
  include PublicWebsiteSlug

  CATEGORIES = %w[
    quran_reading quran_memorization tajweed qaida_noorania arabic_language
    islamic_studies recitation revision new_muslim_foundations other
  ].freeze
  STATUSES = %w[draft active inactive archived].freeze
  AGE_GROUPS = %w[children teenagers adults seniors].freeze
  LEVELS = %w[not_started foundation beginner elementary intermediate advanced memorization revision qualified].freeze
  CODE_PATTERN = /\A[A-Z0-9][A-Z0-9_-]*\z/
  # Public pages never fall back to the other language, so both locales must be complete
  # before a program can be published.
  PUBLIC_REQUIRED_FIELDS = %i[
    slug_ar slug_en name_ar name_en short_description_ar short_description_en
  ].freeze

  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_programs
  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_programs
  has_many :course_offerings, dependent: :restrict_with_exception
  has_many :events, class_name: "ProgramEvent", dependent: :restrict_with_exception
  has_many :exam_sessions, dependent: :restrict_with_exception

  attr_readonly :public_id
  before_validation :normalize_values
  before_validation :normalize_public_slugs
  before_validation :apply_defaults, on: :create
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\APRG-[A-Z0-9]{10}\z/ }
  validates :code, presence: true, uniqueness: { case_sensitive: false }, format: { with: CODE_PATTERN }
  validates :name_ar, :name_en, presence: true, length: { maximum: 200 }
  validates :category, inclusion: { in: CATEGORIES }
  validates :status, inclusion: { in: STATUSES }
  validates :entry_level, :completion_level, inclusion: { in: LEVELS }
  validates :recommended_lessons_per_week, numericality: { only_integer: true, in: 1..14 }
  validates :estimated_duration_weeks, numericality: { only_integer: true, in: 0..520 }, allow_nil: true
  validates :display_order, numericality: { only_integer: true, in: 0..100_000 }
  validates :internal_notes, length: { maximum: 5_000 }, allow_blank: true
  validates :public_display_order, numericality: { only_integer: true, in: 0..100_000 }
  validates :slug_ar, :slug_en, uniqueness: { case_sensitive: false },
                                format: { with: PublicWebsiteSlug::FORMAT },
                                length: { maximum: PublicWebsiteSlug::MAX_LENGTH }, allow_nil: true
  validate :public_content_rules, if: :published?
  validate :language_rules
  validate :age_group_rules
  validate :lesson_duration_rules
  validate :protect_code, if: :will_save_change_to_code?

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
  # Publication requires both an operational `active` status and an explicit `published` flag,
  # so activating a program never makes it public on its own.
  scope :publicly_visible, -> { where(status: "active", published: true) }

  def archived? = status == "archived"
  def active? = status == "active"
  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  def publicly_visible? = active? && published?

  private

  # rubocop:disable Metrics/AbcSize
  def normalize_values
    self.code = code.to_s.strip.upcase
    self.default_learning_language = default_learning_language.to_s.downcase
    self.supported_learning_languages = Array(supported_learning_languages).compact_blank.map do |v|
      v.to_s.downcase
    end.uniq
    self.target_age_groups = Array(target_age_groups).compact_blank.map(&:to_s).uniq
  end
  # rubocop:enable Metrics/AbcSize

  def apply_defaults
    setting = AcademySetting.current_or_nil
    return unless setting

    self.supported_learning_languages = setting.teaching_languages if supported_learning_languages.empty?
    self.default_learning_language = supported_learning_languages.first if default_learning_language.blank?
    self.default_lesson_duration_minutes ||= setting.default_lesson_duration_minutes
  end

  def normalize_public_slugs
    self.slug_ar = self.class.normalize_public_slug(slug_ar)
    self.slug_en = self.class.normalize_public_slug(slug_en)
  end

  def public_content_rules
    PUBLIC_REQUIRED_FIELDS.each do |field|
      errors.add(field, :public_content_required) if public_send(field).blank?
    end
  end

  def generate_public_id
    self.public_id ||= "PRG-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def language_rules
    allowed = AcademySetting.current_or_nil&.teaching_languages.presence || AcademySetting::TEACHING_LANGUAGES
    errors.add(:supported_learning_languages, :invalid) if supported_learning_languages.empty? ||
                                                           (supported_learning_languages - allowed).any?
    return if supported_learning_languages.include?(default_learning_language)

    errors.add(:default_learning_language,
               :not_supported)
  end

  # rubocop:disable Metrics/AbcSize
  def age_group_rules
    errors.add(:target_age_groups, :invalid) if target_age_groups.empty? || (target_age_groups - AGE_GROUPS).any?
    errors.add(:target_age_groups, :minor_not_allowed) if !allows_minor_students? &&
                                                          target_age_groups.intersect?(%w[children teenagers])
    errors.add(:target_age_groups, :adult_not_allowed) if !allows_adult_students? &&
                                                          target_age_groups.intersect?(%w[adults seniors])
  end
  # rubocop:enable Metrics/AbcSize

  def lesson_duration_rules
    setting = AcademySetting.current_or_nil
    return unless setting

    range = setting.minimum_lesson_duration_minutes..setting.maximum_lesson_duration_minutes
    errors.add(:default_lesson_duration_minutes, :outside_range) unless range.cover?(default_lesson_duration_minutes)
    offset = default_lesson_duration_minutes - setting.minimum_lesson_duration_minutes
    return if (offset % setting.lesson_duration_step_minutes).zero?

    errors.add(:default_lesson_duration_minutes,
               :misaligned)
  end

  def protect_code
    errors.add(:code, :operational_history) if persisted? && course_offerings.exists?
  end
end
