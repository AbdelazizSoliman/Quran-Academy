class TeacherProfileEvent < ApplicationRecord
  EVENT_TYPES = %w[
    created updated verified archived restored employment_status_changed
    engagement_type_changed compensation_changed self_updated
  ].freeze
  SENSITIVE_KEY_PATTERN = /(password|token|secret|session|credential|encrypted)/i

  belongs_to :teacher_profile, inverse_of: :events
  belongs_to :actor, class_name: "User", inverse_of: :teacher_profile_events

  validates :event_type, inclusion: { in: EVENT_TYPES }
  validate :metadata_is_safe

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  private

  def metadata_is_safe
    errors.add(:metadata, :unsafe) if unsafe_value?(metadata)
  end

  def unsafe_value?(value)
    case value
    when Hash
      value.any? { |key, nested| key.to_s.match?(SENSITIVE_KEY_PATTERN) || unsafe_value?(nested) }
    when Array
      value.any? { |nested| unsafe_value?(nested) }
    else
      false
    end
  end
end
