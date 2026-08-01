module Admin
  module TeacherAvailabilityExceptions
    class Update < Create
      def initialize(actor:, exception:, attributes:)
        super(actor:, teacher_profile: exception.teacher_profile, attributes:)
        @exception = exception
      end

      def call
        TeacherAvailabilityException.transaction do
          @exception.assign_attributes(@attributes)
          return @exception unless @exception.valid?

          return @exception if @exception.changes.slice(*FIELDS).empty?

          save_changes
        end
        @exception
      rescue ActiveRecord::RecordInvalid
        @exception
      end

      private

      def save_changes
        @exception.update!(updated_by: @actor)
        TeacherAvailabilityExceptionEvent.create!(teacher_availability_exception: @exception, actor: @actor,
                                                  event_type: "updated",
                                                  after_data: audit_changes(@exception, FIELDS))
      end
    end
  end
end
