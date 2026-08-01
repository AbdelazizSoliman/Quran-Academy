module Admin
  module ScheduledLessons
    module Participants
      class Remove
        def initialize(actor:, participant:)
          @actor = actor
          @participant = participant
        end

        def call
          ScheduledLessonEnrollment.transaction do
            @participant.update!(participation_status: "removed")
            ScheduledLessonEvent.create!(scheduled_lesson: @participant.scheduled_lesson, actor: @actor,
                                         event_type: "participant_removed",
                                         before_data: { "participation_status" => "expected" },
                                         after_data: { "participation_status" => "removed" })
          end
          @participant
        rescue ActiveRecord::RecordInvalid
          @participant
        end
      end
    end
  end
end
