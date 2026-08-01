module Admin
  module TeacherAvailabilities
    class Update < Create
      def initialize(actor:, availability:, attributes:)
        super(actor:, teacher_profile: availability.teacher_profile, attributes:)
        @availability = availability
      end

      def call
        TeacherAvailability.transaction do
          @availability.assign_attributes(@attributes)
          return @availability unless @availability.valid?

          before = @availability.attributes.slice(*FIELDS)
          return @availability if @availability.changes.slice(*FIELDS).empty?

          save_changes(before)
        end
        @availability
      rescue ActiveRecord::RecordInvalid
        @availability
      end

      private

      def save_changes(before)
        @availability.update!(updated_by: @actor)
        TeacherAvailabilityEvent.create!(teacher_availability: @availability, actor: @actor, event_type: "updated",
                                         before_data: before, after_data: audit_changes(@availability, FIELDS))
      end
    end
  end
end
