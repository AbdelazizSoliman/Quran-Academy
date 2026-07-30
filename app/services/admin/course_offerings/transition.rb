module Admin
  module CourseOfferings
    class Transition
      RULES = {
        open: { from: %w[draft closed], to: "open", event: "opened", accepts: true },
        close: { from: %w[open], to: "closed", event: "closed", accepts: false },
        start: { from: %w[open closed], to: "in_progress", event: "started", accepts: false },
        complete: { from: %w[in_progress], to: "completed", event: "completed", accepts: false },
        cancel: { from: %w[draft open closed], to: "cancelled", event: "cancelled", accepts: false },
        archive: { from: %w[draft closed completed cancelled], to: "archived", event: "archived", accepts: false },
        restore: { from: %w[archived], to: "closed", event: "restored", accepts: false }
      }.freeze

      def initialize(actor:, offering:, action:)
        @actor = actor
        @offering = offering
        @action = action.to_sym
      end

      # rubocop:disable Metrics/MethodLength
      def call
        rule = RULES.fetch(@action)
        CourseOffering.transaction do
          @offering.lock!
          return invalid unless @offering.status.in?(rule[:from])

          before = @offering.status
          @offering.assign_attributes(status: rule[:to], accepts_new_enrollments: rule[:accepts],
                                      updated_by: @actor)
          @offering.save!
          CourseOfferingEvent.create!(
            course_offering: @offering, actor: @actor, event_type: rule[:event],
            metadata: { "changes" => { "status" => { "from" => before, "to" => rule[:to] } } }
          )
        end
        @offering
      rescue ActiveRecord::RecordInvalid
        @offering
      end
      # rubocop:enable Metrics/MethodLength

      private

      def invalid
        @offering.errors.add(:status, :invalid_transition)
        @offering
      end
    end
  end
end
