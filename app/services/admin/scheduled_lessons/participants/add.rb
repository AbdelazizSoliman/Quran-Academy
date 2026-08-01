module Admin
  module ScheduledLessons
    module Participants
      class Add
        def initialize(actor:, lesson:, enrollment:)
          @actor = actor
          @lesson = lesson
          @enrollment = enrollment
        end

        def call
          record = @lesson.scheduled_lesson_enrollments.build(enrollment: @enrollment, added_by: @actor)
          ScheduledLessonEnrollment.transaction do
            record.save!
            ScheduledLessonEvent.create!(scheduled_lesson: @lesson, actor: @actor, event_type: "participant_added",
                                         after_data: { "enrollment_id" => @enrollment.id })
          end
          record
        rescue ActiveRecord::RecordInvalid
          record
        end
      end
    end
  end
end
