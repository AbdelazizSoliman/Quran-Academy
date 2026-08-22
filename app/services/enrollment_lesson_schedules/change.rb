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
      EnrollmentLessonSchedule.transaction { replacement = change_schedule }
      replacement || @schedule
    end

    private

    def change_schedule
      @schedule.lock!
      return invalid(:not_active) unless @schedule.active?
      return invalid(:invalid_effective_date) unless valid_effective_date?

      supersede_old!
      replacement = create_replacement
      raise ActiveRecord::Rollback if replacement.errors.any?

      replace_future_occurrences!(replacement)
      record_change!(replacement)
      replacement
    end

    def create_replacement
      Create.new(actor: @actor, enrollment: @schedule.enrollment,
                 student_profile: @schedule.enrollment ? nil : @schedule.student_profile,
                 attributes: replacement_attributes, slots: @slots).call
    end

    def record_change!(replacement)
      @schedule.events.create!(actor: @actor, event_type: "changed",
                               metadata: { "replacement_schedule_id" => replacement.id,
                                           "effective_on" => @effective_on })
    end

    def valid_effective_date?
      @effective_on.present? && @effective_on > Date.current && @effective_on > @schedule.starts_on
    end

    def supersede_old!
      @schedule.update!(status: "superseded", ends_on: @effective_on - 1.day, updated_by: @actor)
      @schedule.events.create!(actor: @actor, event_type: "superseded",
                               metadata: { "effective_on" => @effective_on })
    end

    def replace_future_occurrences!(replacement)
      old_slots = ordered_slots(@schedule)
      new_slots = ordered_slots(replacement)
      return cancel_future_occurrences!(old_slots) unless old_slots.size == new_slots.size

      old_slots.zip(new_slots).each do |old_slot, new_slot|
        future_occurrences(old_slot).chronological.each { |lesson| reschedule_occurrence!(lesson, new_slot) }
      end
    end

    def ordered_slots(schedule) = schedule.slots.order(:position, :id).to_a

    def future_occurrences(slot)
      slot.scheduled_lessons.where(recurrence_date: @effective_on.., status: "scheduled")
    end

    def reschedule_occurrence!(lesson, new_slot)
      recurrence_date = replacement_date(lesson.recurrence_date, new_slot.weekday)
      starts_at = local_start(recurrence_date, new_slot.starts_at_local)
      Admin::ScheduledLessons::Reschedule.new(
        actor: @actor, lesson:, starts_at:, ends_at: starts_at + replacement_duration.minutes,
        attributes: {
          teacher_profile_id: replacement_teacher_id,
          enrollment_lesson_schedule_slot_id: new_slot.id,
          recurrence_date:
        }
      ).call
    end

    def cancel_future_occurrences!(old_slots = @schedule.slots)
      old_slots.each do |slot|
        slot.scheduled_lessons.where(recurrence_date: @effective_on.., status: %w[draft scheduled])
            .find_each do |lesson|
          Admin::ScheduledLessons::Transition.new(
            actor: @actor, lesson:, action: :cancel, cancellation_reason: "Recurring schedule changed"
          ).call
        end
      end
    end

    def replacement_date(original_date, weekday)
      target = original_date.beginning_of_week(:sunday) + Date::DAYNAMES.index(weekday.capitalize).days
      target < @effective_on ? target + 1.week : target
    end

    def local_start(date, time)
      zone = ActiveSupport::TimeZone[replacement_time_zone]
      zone.local(date.year, date.month, date.day, time.hour, time.min, time.sec)
    end

    def replacement_duration = @attributes.to_h.symbolize_keys.fetch(:lesson_duration_minutes)

    def replacement_teacher_id = @attributes.to_h.symbolize_keys.fetch(:teacher_profile).id

    def replacement_time_zone = @attributes.to_h.symbolize_keys.fetch(:time_zone)

    def replacement_attributes
      @attributes.to_h.symbolize_keys.merge(starts_on: @effective_on, status: "active")
    end

    def invalid(code)
      @schedule.errors.add(:base, code)
      @schedule
    end
  end
end
