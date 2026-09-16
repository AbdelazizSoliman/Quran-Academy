module StudentLearningProfiles
  class UpsertItem
    FIELDS = %w[value sensitivity visibility].freeze

    def initialize(actor:, section:, field_key:, attributes:)
      @actor = actor
      @section = section
      @field_key = field_key.to_s
      @attributes = attributes.to_h.stringify_keys.slice(*FIELDS)
    end

    def call
      item = @section.items.find_or_initialize_by(field_key: @field_key)
      return forbidden(item) unless authorized?(item)

      StudentLearningProfileItem.transaction { persist(item) }
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      item
    end

    private

    def persist(item)
      new_record = item.new_record?
      item.assign_attributes(@attributes)
      item.created_by ||= @actor
      item.source ||= source
      return item unless item.changed?

      item.updated_by = @actor
      item.save!
      create_event(item, new_record)
      item
    end

    def create_event(item, new_record)
      changes = item.previous_changes.slice(*FIELDS)
      sensitive = item.sensitivity.in?(%w[sensitive highly_sensitive])
      item.student_learning_profile.events.create!(
        section: @section, item:, actor: @actor, action: new_record ? "item_created" : "item_updated",
        field_key: item.field_key, source:, previous_value: sensitive ? nil : changes.transform_values(&:first),
        new_value: sensitive ? nil : changes.transform_values(&:last),
        metadata: sensitive ? { "sensitive_value_changed" => true } : {}
      )
    end

    def authorized?(item)
      access = Access.new(@actor)
      return false unless access.can_write?(@section.student_learning_profile.student_profile)
      return true if access.can_manage_highly_sensitive?

      teacher_authorized?(item)
    end

    def teacher_authorized?(item)
      return false if item.persisted? && item.sensitivity == "highly_sensitive"
      return false if requested_sensitivity(item) == "highly_sensitive"
      return false if sensitivity_downgrade?(item)

      !protected?(item) || requested_visibility(item) == "internal"
    end

    def requested_sensitivity(item)
      @attributes.fetch("sensitivity") { item.sensitivity || field_definition.fetch(:sensitivity) }
    end

    def requested_visibility(item)
      @attributes.fetch("visibility") { item.visibility || field_definition.fetch(:visibility) }
    end

    def field_definition
      StudentLearningProfileFieldRegistry.fetch(@section.section_key, @field_key) || {}
    end

    def protected?(item) = item.sensitivity != "standard" || requested_sensitivity(item) != "standard"

    def sensitivity_downgrade?(item)
      return false unless item.persisted?

      StudentLearningProfileItem::SENSITIVITY_RANK.fetch(requested_sensitivity(item)) <
        StudentLearningProfileItem::SENSITIVITY_RANK.fetch(item.sensitivity)
    end

    def source = @actor.admin? ? "admin_entry" : "teacher_entry"

    def forbidden(item)
      item.errors.add(:base, :forbidden)
      item
    end
  end
end
