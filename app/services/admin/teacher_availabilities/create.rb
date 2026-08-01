module Admin
  module TeacherAvailabilities
    class Create < Admin::SchedulingOperation
      FIELDS = %w[weekday starts_at_local ends_at_local time_zone effective_from effective_until availability_type
                  notes].freeze

      def initialize(actor:, teacher_profile:, attributes:)
        super()
        @actor = actor
        @teacher_profile = teacher_profile
        @attributes = attributes
      end

      def call
        record = @teacher_profile.availabilities.build(@attributes)
        record.created_by = record.updated_by = @actor
        TeacherAvailability.transaction do
          record.save!
          TeacherAvailabilityEvent.create!(teacher_availability: record, actor: @actor, event_type: "created",
                                           after_data: audit_changes(record, FIELDS))
        end
        record
      rescue ActiveRecord::RecordInvalid
        record
      end
    end
  end
end
