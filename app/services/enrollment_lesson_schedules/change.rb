module EnrollmentLessonSchedules
  class Change
    def initialize(actor:, schedule:, effective_on:, attributes:, slots:)
      @actor = actor
      @schedule = schedule
      @effective_on = effective_on
      @attributes = attributes
      @slots = slots
    end

    def call
      replacement = nil
      EnrollmentLessonSchedule.transaction do
        @schedule.lock!
        return invalid(:not_active) unless @schedule.active?
        return invalid(:invalid_effective_date) unless valid_effective_date?

        supersede_old!
        cancel_future_occurrences!
        replacement = Create.new(actor: @actor, enrollment: @schedule.enrollment,
                                 attributes: replacement_attributes, slots: @slots).call
        raise ActiveRecord::Rollback if replacement.errors.any?

        @schedule.events.create!(actor: @actor, event_type: "changed",
                                 metadata: { "replacement_schedule_id" => replacement.id,
                                             "effective_on" => @effective_on })
      end
      replacement || @schedule
    end

    private

    def valid_effective_date?
      @effective_on.present? && @effective_on > Date.current && @effective_on > @schedule.starts_on
    end

    def supersede_old!
      @schedule.update!(status: "superseded", ends_on: @effective_on - 1.day, updated_by: @actor)
      @schedule.events.create!(actor: @actor, event_type: "superseded",
                               metadata: { "effective_on" => @effective_on })
    end

    def cancel_future_occurrences!
      lessons = ScheduledLesson.joins(:enrollment_lesson_schedule_slot)
                               .where(enrollment_lesson_schedule_slots: {
                                        enrollment_lesson_schedule_id: @schedule.id
                                      }, recurrence_date: @effective_on..)
                               .where(status: %w[draft scheduled])
      lessons.find_each do |lesson|
        Admin::ScheduledLessons::Transition.new(
          actor: @actor, lesson:, action: :cancel, cancellation_reason: "Recurring schedule changed"
        ).call
      end
    end

    def replacement_attributes
      @attributes.to_h.symbolize_keys.merge(starts_on: @effective_on, status: "active")
    end

    def invalid(code)
      @schedule.errors.add(:base, code)
      @schedule
    end
  end
end
