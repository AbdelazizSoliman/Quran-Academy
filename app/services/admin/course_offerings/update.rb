module Admin
  module CourseOfferings
    class Update < Create
      def initialize(actor:, offering:, attributes:)
        super(actor:, program: offering.program, attributes:)
        @offering = offering
      end

      # rubocop:disable Metrics/MethodLength
      def call
        CourseOffering.transaction do
          @offering.lock!
          @offering.assign_attributes(@attributes)
          return @offering unless @offering.valid?

          changes = safe_changes(@offering, FIELDS)
          return @offering if changes.empty?

          @offering.updated_by = @actor
          @offering.save!
          event = changes.key?("capacity") ? "capacity_changed" : "updated"
          CourseOfferingEvent.create!(course_offering: @offering, actor: @actor, event_type: event,
                                      metadata: { "changes" => changes })
        end
        @offering
      rescue ActiveRecord::RecordInvalid
        @offering
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
