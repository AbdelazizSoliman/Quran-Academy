class UserAccountEvent < ApplicationRecord
  EVENT_TYPES = %w[
    created updated approved suspended activated disabled enabled role_changed password_reset
  ].freeze
  SENSITIVE_KEYS = %w[
    password password_confirmation encrypted_password reset_password_token
    remember_token session_id
  ].freeze

  belongs_to :target_user, class_name: "User", inverse_of: :account_events
  belongs_to :actor, class_name: "User", inverse_of: :performed_account_events

  validates :event_type, inclusion: { in: EVENT_TYPES }
  validate :metadata_contains_no_sensitive_keys

  private

  def metadata_contains_no_sensitive_keys
    keys = metadata_keys(metadata)
    errors.add(:metadata, :sensitive) if keys.intersect?(SENSITIVE_KEYS)
  end

  def metadata_keys(value)
    return value.flat_map { |key, nested| [key.to_s, *metadata_keys(nested)] } if value.is_a?(Hash)
    return value.flat_map { |nested| metadata_keys(nested) } if value.is_a?(Array)

    []
  end
end
