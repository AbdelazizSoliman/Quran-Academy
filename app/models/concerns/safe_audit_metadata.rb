module SafeAuditMetadata
  extend ActiveSupport::Concern

  SENSITIVE_KEY_PATTERN = /(password|token|secret|session|credential|encrypted)/i

  included { validate :metadata_is_safe }

  private

  def metadata_is_safe
    errors.add(:metadata, :unsafe) if unsafe_value?(metadata)
  end

  def unsafe_value?(value)
    case value
    when Hash
      value.any? { |key, nested| key.to_s.match?(SENSITIVE_KEY_PATTERN) || unsafe_value?(nested) }
    when Array then value.any? { |nested| unsafe_value?(nested) }
    else false
    end
  end
end
