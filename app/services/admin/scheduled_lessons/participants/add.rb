module Admin
  module ScheduledLessons
    module Participants
      class Add
        def initialize(actor:, lesson:, enrollment: nil, student_profile: nil)
          @actor = actor
          @lesson = lesson
          @enrollment = enrollment
          @student_profile = student_profile
        end

        def call
          record = @lesson.scheduled_lesson_enrollments.build(enrollment: @enrollment,
                                                              student_profile: @student_profile, added_by: @actor)
          ScheduledLessonEnrollment.transaction do
            record.save!
            LessonAttendances::Initialize.new(actor: @actor, lesson: @lesson).call! if @lesson.attendance_editable?
            event!
          end
          record
        rescue ActiveRecord::RecordInvalid
          record
        end

        private

        def event!
          ScheduledLessonEvent.create!(scheduled_lesson: @lesson, actor: @actor, event_type: "participant_added",
                                       after_data: { "enrollment_id" => @enrollment&.id,
                                                     "student_profile_id" => @student_profile&.id }.compact)
        end
      end
    end
  end
end
