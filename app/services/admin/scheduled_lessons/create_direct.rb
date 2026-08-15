module Admin
  module ScheduledLessons
    # Creates a single enrollment-less lesson for a fee-plan-only (direct) student: a real
    # ScheduledLesson with course_offering_id: nil, plus a direct ScheduledLessonEnrollment —
    # reusing Create and Participants::Add rather than duplicating either concern.
    class CreateDirect
      def initialize(actor:, attributes:)
        @actor = actor
        attributes = attributes.to_h.symbolize_keys
        @student_profile_id = attributes.delete(:student_profile_id)
        @lesson_attributes = attributes.except(:lesson_type).merge(course_offering_id: nil)
      end

      def call
        lesson = nil
        ScheduledLesson.transaction(requires_new: true) do
          lesson = Create.new(actor: @actor, attributes: @lesson_attributes).call
          raise ActiveRecord::Rollback unless lesson.persisted? && lesson.errors.empty?
          raise ActiveRecord::Rollback unless attach_student!(lesson)
        end
        lesson
      end

      private

      # rubocop:disable Naming/PredicateMethod -- named with `!` (mutates lesson.errors), not `?`
      def attach_student!(lesson)
        student_profile = StudentProfile.find_by(id: @student_profile_id)
        unless student_profile
          lesson.errors.add(:base, :student_required)
          return false
        end

        participant = Participants::Add.new(actor: @actor, lesson:, student_profile:).call
        return true if participant.errors.empty?

        participant.errors.each { |error| lesson.errors.add(:base, error.type) }
        false
      end
      # rubocop:enable Naming/PredicateMethod
    end
  end
end
