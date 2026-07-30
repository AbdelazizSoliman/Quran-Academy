module Admin
  module Enrollments
    class Update < Create
      def initialize(actor:, enrollment:, attributes:)
        super(actor:, student_profile: enrollment.student_profile,
              course_offering: enrollment.course_offering, attributes:)
        @enrollment = enrollment
      end

      # rubocop:disable Metrics/MethodLength
      def call
        Enrollment.transaction do
          @enrollment.lock!
          @enrollment.assign_attributes(@attributes)
          return @enrollment unless @enrollment.valid?

          changes = safe_changes(@enrollment, FIELDS)
          return @enrollment if changes.empty?

          @enrollment.updated_by = @actor
          @enrollment.save!
          EnrollmentEvent.create!(enrollment: @enrollment, actor: @actor, event_type: "updated",
                                  metadata: references(@enrollment).merge("changes" => changes))
        end
        @enrollment
      rescue ActiveRecord::RecordInvalid
        @enrollment
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
