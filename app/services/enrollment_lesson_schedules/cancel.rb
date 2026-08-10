module EnrollmentLessonSchedules
  class Cancel
    def initialize(actor:, schedule:, effective_on: Date.current)
      @actor = actor
      @schedule = schedule
      @effective_on = effective_on
    end

    def call
      EnrollmentLessonSchedule.transaction do
        @schedule.lock!
        return invalid unless @schedule.active?

        ending = [@schedule.ends_on, [@effective_on, @schedule.starts_on].max].compact.min
        @schedule.update!(status: "cancelled", ends_on: ending,
                          updated_by: @actor)
        cancel_future_occurrences!
        @schedule.events.create!(actor: @actor, event_type: "cancelled",
                                 metadata: { "effective_on" => @effective_on })
      end
      @schedule
    end

    private

    def cancel_future_occurrences!
      lessons = ScheduledLesson.joins(:enrollment_lesson_schedule_slot)
                               .where(enrollment_lesson_schedule_slots: {
                                        enrollment_lesson_schedule_id: @schedule.id
                                      }, recurrence_date: @effective_on.., status: %w[draft scheduled])
      lessons.find_each do |lesson|
        Admin::ScheduledLessons::Transition.new(
          actor: @actor, lesson:, action: :cancel, cancellation_reason: "Recurring schedule cancelled"
        ).call
      end
    end

    def invalid
      @schedule.errors.add(:base, :not_active)
      @schedule
    end
  end
end
