module Admin
  module TeacherAvailabilityExceptions
    class Transition < Create
      def initialize(actor:, exception:, action:)
        super(actor:, teacher_profile: exception.teacher_profile, attributes: {})
        @exception = exception
        @action = action.to_sym
      end

      def call
        target = @action == :cancel ? "cancelled" : "archived"
        return invalid unless @exception.status == "active"

        transition(target)
      rescue ActiveRecord::RecordInvalid
        @exception
      end

      private

      def transition(target)
        TeacherAvailabilityException.transaction do
          @exception.update!(status: target, updated_by: @actor)
          TeacherAvailabilityExceptionEvent.create!(teacher_availability_exception: @exception, actor: @actor,
                                                    event_type: @action.to_s, before_data: { "status" => "active" },
                                                    after_data: { "status" => target })
        end
        @exception
      end

      def invalid
        @exception.errors.add(:status, :invalid_transition)
        @exception
      end
    end
  end
end
