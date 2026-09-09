module Admin
  module Website
    # Updates only the public website presentation of a Program. Operational catalog data is
    # untouched, and every change is recorded as a `public_profile_updated` program event.
    class UpdateProgramPublicProfile < AcademicCatalogOperation
      FIELDS = %w[published slug_ar slug_en public_featured public_display_order].freeze

      def initialize(actor:, program:, attributes:)
        super()
        @actor = actor
        @program = program
        @attributes = attributes
      end

      def call
        Program.transaction do
          @program.lock!
          @program.assign_attributes(@attributes)
          return @program unless @program.valid?

          changes = safe_changes(@program, FIELDS)
          persist(changes) if changes.any?
        end
        @program
      rescue ActiveRecord::RecordInvalid
        @program
      end

      private

      def persist(changes)
        @program.updated_by = @actor
        @program.save!
        ProgramEvent.create!(program: @program, actor: @actor, event_type: "public_profile_updated",
                             metadata: { "changes" => changes })
      end
    end
  end
end
