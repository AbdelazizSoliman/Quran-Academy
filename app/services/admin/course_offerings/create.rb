module Admin
  module CourseOfferings
    class Create < AcademicCatalogOperation
      FIELDS = %w[
        program_id code title_ar title_en description_ar description_en learning_language
        delivery_mode target_age_groups enrollment_opens_on enrollment_closes_on planned_start_on
        planned_end_on capacity default_lesson_duration_minutes intended_lessons_per_week
        placement_required accepts_new_enrollments internal_notes
      ].freeze

      def initialize(actor:, program:, attributes:)
        super()
        @actor = actor
        @program = program
        @attributes = attributes
      end

      # Creation is transactional so the offering and its audit event stay atomic.
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def call
        defaults = {
          learning_language: @program.default_learning_language,
          target_age_groups: @program.target_age_groups,
          default_lesson_duration_minutes: @program.default_lesson_duration_minutes,
          intended_lessons_per_week: @program.recommended_lessons_per_week,
          placement_required: @program.requires_placement
        }
        attributes = @attributes.to_h.symbolize_keys
        offering = @program.course_offerings.build(defaults.merge(attributes))
        offering.instance_variable_set(:@placement_required_explicit, true) if attributes.key?(:placement_required)
        offering.created_by = offering.updated_by = @actor
        CourseOffering.transaction do
          offering.save!
          CourseOfferingEvent.create!(course_offering: offering, actor: @actor, event_type: "created",
                                      metadata: { "changes" => safe_changes(offering, FIELDS) })
        end
        offering
      rescue ActiveRecord::RecordInvalid
        offering
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
    end
  end
end
