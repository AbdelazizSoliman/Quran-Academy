module Admin
  module Enrollments
    class Create < AcademicCatalogOperation
      FIELDS = %w[
        application_source student_goals_snapshot preferred_schedule_notes placement_notes
        administrator_notes starting_quran_level starting_reading_level starting_tajweed_level
        starting_memorization_level starting_memorized_juz_count
      ].freeze

      def initialize(actor:, student_profile:, course_offering:, attributes:)
        super()
        @actor = actor
        @student_profile = student_profile
        @course_offering = course_offering
        @attributes = attributes
      end

      # rubocop:disable Metrics/MethodLength
      def call
        enrollment = Enrollment.new(@attributes.merge(student_profile: @student_profile,
                                                      course_offering: @course_offering))
        enrollment.created_by = enrollment.updated_by = @actor
        Enrollment.transaction do
          enrollment.save!
          EnrollmentEvent.create!(
            enrollment:, actor: @actor, event_type: "created",
            metadata: references(enrollment).merge("changes" => safe_changes(enrollment, FIELDS))
          )
        end
        enrollment
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        enrollment.errors.add(:base, :duplicate) if enrollment.errors.empty?
        enrollment
      end
      # rubocop:enable Metrics/MethodLength

      private

      def references(enrollment)
        { "student_public_id" => enrollment.student_profile.public_id,
          "offering_public_id" => enrollment.course_offering.public_id }
      end
    end
  end
end
