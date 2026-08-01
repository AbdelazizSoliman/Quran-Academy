module Admin
  module ScheduledLessons
    module Participants
      class Remove
        def initialize(actor:, participant:)
          @actor = actor
          @participant = participant
        end

        def call
          return locked_participant if @participant.scheduled_lesson.attendance_locked?

          ScheduledLessonEnrollment.transaction { remove! }
          @participant
        rescue ActiveRecord::RecordInvalid
          @participant
        end

        private

        def locked_participant
          @participant.errors.add(:base, :attendance_locked)
          @participant
        end

        def remove!
          @participant.update!(participation_status: "removed")
          mark_attendance_not_applicable
          ScheduledLessonEvent.create!(scheduled_lesson: @participant.scheduled_lesson, actor: @actor,
                                       event_type: "participant_removed",
                                       before_data: { "participation_status" => "expected" },
                                       after_data: { "participation_status" => "removed" })
        end

        def mark_attendance_not_applicable
          attendance = @participant.lesson_attendance
          return unless attendance && @participant.scheduled_lesson.attendance_editable?

          LessonAttendances::MarkNotApplicable.new(actor: @actor, attendance:).call!
        end
      end
    end
  end
end
