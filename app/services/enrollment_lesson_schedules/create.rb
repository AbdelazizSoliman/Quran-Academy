module EnrollmentLessonSchedules
  class Create
    def initialize(actor:, enrollment:, attributes:, slots:)
      @actor = actor
      @enrollment = enrollment
      @attributes = attributes.to_h.symbolize_keys
      @slots = Array(slots)
    end

    def call
      schedule = @enrollment.lesson_schedules.new(@attributes)
      schedule.created_by = schedule.updated_by = @actor
      EnrollmentLessonSchedule.transaction(requires_new: true) do
        schedule.save!
        create_slots!(schedule)
        raise ActiveRecord::RecordInvalid, schedule if schedule.slots.empty?

        event!(schedule, "created")
      end
      enqueue_generation_after_commit(schedule)
      schedule
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      schedule.errors.add(:base, :invalid_slots) if schedule.errors.empty?
      schedule.errors.add(:base, :duplicate_slot) if e.is_a?(ActiveRecord::RecordNotUnique)
      schedule
    end

    private

    def create_slots!(schedule)
      @slots.each_with_index do |slot, position|
        values = slot.to_h.symbolize_keys
        schedule.slots.create!(weekday: values[:weekday], starts_at_local: values[:starts_at_local], position:)
      end
    end

    def event!(schedule, type)
      schedule.events.create!(actor: @actor, event_type: type,
                              metadata: { "slot_count" => schedule.slots.size })
    end

    def enqueue_generation_after_commit(schedule)
      return unless schedule.active?

      ActiveRecord.after_all_transactions_commit do
        GenerateOccurrences.new(schedule:, actor: @actor).call
      end
    end
  end
end
