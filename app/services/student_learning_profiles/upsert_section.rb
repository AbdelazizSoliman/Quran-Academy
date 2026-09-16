module StudentLearningProfiles
  class UpsertSection
    FIELDS = %w[completion_state review_state].freeze

    def initialize(actor:, profile:, section_key:, attributes: {})
      @actor = actor
      @profile = profile
      @section_key = section_key.to_s
      @attributes = attributes.to_h.stringify_keys.slice(*FIELDS)
    end

    def call
      return forbidden_section unless Access.new(@actor).can_write?(@profile.student_profile)
      return forbidden_section if unauthorized_review_transition?

      StudentLearningProfileSection.transaction do
        persist(section_record)
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      section_record
    end

    private

    def source = @actor.admin? ? "admin_entry" : "teacher_entry"

    def section_record
      @section_record ||= @profile.sections.find_or_initialize_by(section_key: @section_key)
    end

    def persist(section)
      action = section.new_record? ? "section_created" : "section_updated"
      section.assign_attributes(@attributes)
      section.created_by ||= @actor
      assign_review_metadata(section)
      return section unless section.changed?

      section.updated_by = @actor
      section.save!
      create_event(section, action)
      section
    end

    def create_event(section, action)
      changes = section.previous_changes.slice(*FIELDS, "reviewed_at", "reviewed_by_id")
      @profile.events.create!(section:, actor: @actor, action:, source:,
                              previous_value: changes.transform_values(&:first),
                              new_value: changes.transform_values(&:last))
    end

    def unauthorized_review_transition?
      @attributes.key?("review_state") && @attributes["review_state"] != section_record.review_state && !@actor.admin?
    end

    def assign_review_metadata(section)
      return unless section.will_save_change_to_review_state?

      if section.review_state == "reviewed"
        section.reviewed_by = @actor
        section.reviewed_at = Time.current
      else
        section.reviewed_by = nil
        section.reviewed_at = nil
      end
    end

    def forbidden_section
      section_record.tap do |section|
        section.created_by ||= @actor
        section.updated_by ||= @actor
        section.errors.add(:base, :forbidden)
      end
    end
  end
end
