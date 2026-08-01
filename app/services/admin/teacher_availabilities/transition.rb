module Admin
  module TeacherAvailabilities
    class Transition < Create
      RULES = { activate: %w[inactive], deactivate: %w[active], archive: %w[active inactive] }.freeze

      def initialize(actor:, availability:, action:)
        super(actor:, teacher_profile: availability.teacher_profile, attributes: {})
        @availability = availability
        @action = action.to_sym
      end

      def call
        from = RULES.fetch(@action)
        return invalid unless @availability.status.in?(from)

        transition(from, target_status)
      rescue ActiveRecord::RecordInvalid
        @availability
      end

      private

      def transition(from, target)
        TeacherAvailability.transaction do
          @availability.update!(status: target, updated_by: @actor)
          TeacherAvailabilityEvent.create!(teacher_availability: @availability, actor: @actor,
                                           event_type: event_type,
                                           before_data: { "status" => from }, after_data: { "status" => target })
        end
        @availability
      end

      def target_status
        { activate: "active", deactivate: "inactive", archive: "archived" }.fetch(@action)
      end

      def event_type
        { activate: "activated", deactivate: "deactivated", archive: "archived" }.fetch(@action)
      end

      def invalid
        @availability.errors.add(:status, :invalid_transition)
        @availability
      end
    end
  end
end
