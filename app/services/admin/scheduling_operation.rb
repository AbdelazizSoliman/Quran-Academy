module Admin
  class SchedulingOperation
    def initialize
      # Intentionally stateless; subclasses own operation-specific state.
    end

    private

    def audit_changes(record, fields)
      record.saved_changes.slice(*fields).transform_values do |change|
        { "from" => serialize(change.first), "to" => serialize(change.last) }
      end
    end

    def serialize(value)
      value.is_a?(BigDecimal) ? value.to_s("F") : value
    end
  end
end
