module Admin
  module Programs
    class Transition
      RULES = {
        activate: { from: %w[draft inactive], to: "active", event: "activated" },
        deactivate: { from: %w[active], to: "inactive", event: "deactivated" },
        archive: { from: %w[draft inactive], to: "archived", event: "archived" },
        restore: { from: %w[archived], to: "inactive", event: "restored" }
      }.freeze

      def initialize(actor:, program:, action:)
        @actor = actor
        @program = program
        @action = action.to_sym
      end

      # rubocop:disable Metrics/MethodLength
      def call
        rule = RULES.fetch(@action)
        Program.transaction do
          @program.lock!
          return invalid unless @program.status.in?(rule[:from])
          return blocked_by_offerings if blocks_operational_offerings?

          before = @program.status
          @program.update!(status: rule[:to], updated_by: @actor)
          ProgramEvent.create!(program: @program, actor: @actor, event_type: rule[:event],
                               metadata: { "changes" => { "status" => { "from" => before, "to" => rule[:to] } } })
        end
        @program
      rescue ActiveRecord::RecordInvalid
        @program
      end
      # rubocop:enable Metrics/MethodLength

      private

      def invalid
        @program.errors.add(:status, :invalid_transition)
        @program
      end

      def blocks_operational_offerings?
        @action.in?(%i[deactivate archive]) &&
          @program.course_offerings.exists?(status: %w[open in_progress])
      end

      def blocked_by_offerings
        @program.errors.add(:status, :operational_offerings_exist)
        @program
      end
    end
  end
end
