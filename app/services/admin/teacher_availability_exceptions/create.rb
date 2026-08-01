module Admin
  module TeacherAvailabilityExceptions
    class Create < Admin::SchedulingOperation
      FIELDS = %w[exception_date starts_at_local ends_at_local time_zone exception_type status reason].freeze

      def initialize(actor:, teacher_profile:, attributes:)
        super()
        @actor = actor
        @teacher_profile = teacher_profile
        @attributes = attributes
      end

      def call
        record = @teacher_profile.availability_exceptions.build(@attributes)
        record.created_by = record.updated_by = @actor
        TeacherAvailabilityException.transaction do
          record.save!
          TeacherAvailabilityExceptionEvent.create!(teacher_availability_exception: record, actor: @actor,
                                                    event_type: "created", after_data: audit_changes(record, FIELDS))
        end
        record
      rescue ActiveRecord::RecordInvalid
        record
      end
    end
  end
end
