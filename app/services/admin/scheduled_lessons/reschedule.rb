module Admin
  module ScheduledLessons
    class Reschedule < Update
      def initialize(actor:, lesson:, starts_at:, ends_at:)
        super(actor:, lesson:, attributes: { starts_at:, ends_at:, scheduling_source: "rescheduled" })
      end

      def call
        ScheduledLesson.transaction do
          @lesson.lock!
          return @lesson unless @lesson.status.in?(%w[scheduled in_progress])

          result = super
          create_rescheduled_event if result.errors.empty?
          result
        end
      end

      private

      def create_rescheduled_event
        ScheduledLessonEvent.create!(
          scheduled_lesson: @lesson, actor: @actor, event_type: "rescheduled", before_data: {},
          after_data: { "starts_at" => @lesson.starts_at, "ends_at" => @lesson.ends_at }
        )
      end
    end
  end
end
