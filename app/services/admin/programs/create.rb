module Admin
  module Programs
    class Create < AcademicCatalogOperation
      FIELDS = %w[
        code name_ar name_en short_description_ar short_description_en description_ar description_en
        category default_learning_language supported_learning_languages target_age_groups entry_level
        completion_level default_lesson_duration_minutes recommended_lessons_per_week estimated_duration_weeks
        requires_placement allows_minor_students allows_adult_students display_order internal_notes
      ].freeze

      def initialize(actor:, attributes:)
        super()
        @actor = actor
        @attributes = attributes
      end

      def call
        program = Program.new(@attributes)
        program.created_by = program.updated_by = @actor
        Program.transaction do
          program.save!
          ProgramEvent.create!(program:, actor: @actor, event_type: "created",
                               metadata: { "changes" => safe_changes(program, FIELDS) })
        end
        program
      rescue ActiveRecord::RecordInvalid
        program
      end
    end
  end
end
