class AcademySettingEvent < ApplicationRecord
  EVENT_TYPES = %w[updated].freeze
  SENSITIVE_KEYS = /password|secret|token|credential|session/i

  belongs_to :academy_setting, inverse_of: :events
  belongs_to :actor, class_name: "User"

  validates :event_type, inclusion: { in: EVENT_TYPES }
  validate :metadata_is_safe

  private

  def metadata_is_safe
    errors.add(:metadata, :sensitive) if metadata_keys(metadata).any? { |key| key.match?(SENSITIVE_KEYS) }
  end

  def metadata_keys(value)
    return value.flat_map { |key, nested| [key.to_s, *metadata_keys(nested)] } if value.is_a?(Hash)
    return value.flat_map { |nested| metadata_keys(nested) } if value.is_a?(Array)

    []
  end
end
