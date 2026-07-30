module Admin
  module Programs
    class Update < Create
      def initialize(actor:, program:, attributes:)
        super(actor:, attributes:)
        @program = program
      end

      # rubocop:disable Metrics/MethodLength
      def call
        Program.transaction do
          @program.lock!
          @program.assign_attributes(@attributes)
          return @program unless @program.valid?

          changes = safe_changes(@program, FIELDS)
          return @program if changes.empty?

          @program.updated_by = @actor
          @program.save!
          ProgramEvent.create!(program: @program, actor: @actor, event_type: "updated",
                               metadata: { "changes" => changes })
        end
        @program
      rescue ActiveRecord::RecordInvalid
        @program
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
