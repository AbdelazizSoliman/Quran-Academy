module Admin
  module ScheduledLessons
    class Update < Create
      def initialize(actor:, lesson:, attributes:)
        super(actor:, attributes:)
        @lesson = lesson
      end

      def call
        ScheduledLesson.transaction do
          return @lesson unless assign_valid_attributes?

          changes = @lesson.changes.slice(*FIELDS)
          return @lesson if changes.empty?

          save_changes(changes)
        end
        @lesson
      rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
        @lesson.errors.add(:base, :stale_record) if @lesson.errors.empty?
        @lesson
      end

      private

      def normalize_attributes
        super.except(:academy_time_zone)
      end

      def assign_valid_attributes?
        @lesson.assign_attributes(normalize_attributes)
        @lesson.valid?
      end

      def save_changes(changes)
        @lesson.update!(updated_by: @actor)
        ScheduledLessonEvent.create!(
          scheduled_lesson: @lesson, actor: @actor, event_type: "updated",
          before_data: changes.transform_values(&:first), after_data: changes.transform_values(&:last)
        )
      end
    end
  end
end
