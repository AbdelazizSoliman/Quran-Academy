class ProfileAuditOperation
  SENSITIVE_FIELDS = %w[
    medical_notes safeguarding_notes special_learning_needs internal_notes notes
  ].freeze

  private

  def audited_changes(record, fields)
    record.changes.slice(*fields).transform_values do |before, after|
      { "from" => serialize(before), "to" => serialize(after) }
    end
  end

  def masked_changes(record, fields)
    audited_changes(record, fields).transform_values.with_index do |value, index|
      field = audited_changes(record, fields).keys[index]
      SENSITIVE_FIELDS.include?(field) ? { "changed" => true } : value
    end
  end

  def serialize(value)
    value.is_a?(BigDecimal) ? value.to_s("F") : value
  end
end
