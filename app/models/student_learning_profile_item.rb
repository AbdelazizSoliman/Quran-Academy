class StudentLearningProfileItem < ApplicationRecord
  VALUE_TYPES = %w[text number boolean list date].freeze
  SENSITIVITY_LEVELS = %w[standard sensitive highly_sensitive].freeze
  VISIBILITY_LEVELS = %w[internal guardian_safe student_safe].freeze
  SOURCES = %w[teacher_entry admin_entry observation].freeze
  FIELD_KEY_FORMAT = /\A[a-z][a-z0-9_]*\z/
  MAX_SERIALIZED_VALUE_BYTES = 10_000
  SENSITIVITY_RANK = { "standard" => 0, "sensitive" => 1, "highly_sensitive" => 2 }.freeze

  belongs_to :section, class_name: "StudentLearningProfileSection",
                       foreign_key: :student_learning_profile_section_id, inverse_of: :items
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  has_many :events, class_name: "StudentLearningProfileEvent", inverse_of: :item, dependent: :restrict_with_exception

  before_validation :apply_field_defaults

  validates :field_key, presence: true, format: { with: FIELD_KEY_FORMAT },
                        uniqueness: { scope: :student_learning_profile_section_id }
  validates :value_type, inclusion: { in: VALUE_TYPES }
  validates :sensitivity, inclusion: { in: SENSITIVITY_LEVELS }
  validates :visibility, inclusion: { in: VISIBILITY_LEVELS }
  validates :source, inclusion: { in: SOURCES }
  validate :registered_field
  validate :definition_consistency
  validate :value_matches_type
  validate :iso_date_value
  validate :value_size

  delegate :student_learning_profile, to: :section

  private

  def apply_field_defaults
    return unless definition

    self.value_type ||= definition.fetch(:value_type)
    self.sensitivity ||= definition.fetch(:sensitivity)
    self.visibility ||= definition.fetch(:visibility)
  end

  def registered_field
    errors.add(:field_key, :not_registered) unless definition
  end

  def definition_consistency
    return unless definition

    errors.add(:value_type, :does_not_match_definition) if value_type != definition.fetch(:value_type)
    minimum = definition.fetch(:sensitivity)
    return if SENSITIVITY_RANK.fetch(sensitivity, -1) >= SENSITIVITY_RANK.fetch(minimum)

    errors.add(:sensitivity, :below_minimum)
  end

  def value_matches_type
    expected = {
      "text" => String, "number" => Numeric, "boolean" => [TrueClass, FalseClass],
      "list" => Array, "date" => String
    }[value_type]
    return if expected && Array(expected).any? { |klass| value.is_a?(klass) }

    errors.add(:value, :invalid_type)
  end

  def iso_date_value
    return unless value_type == "date" && value.is_a?(String)

    Date.iso8601(value)
  rescue Date::Error
    errors.add(:value, :invalid_date)
  end

  def value_size
    return if value.nil? || JSON.generate(value).bytesize <= MAX_SERIALIZED_VALUE_BYTES

    errors.add(:value, :too_large)
  end

  def definition
    return unless section

    StudentLearningProfileFieldRegistry.fetch(section.section_key, field_key)
  end
end
