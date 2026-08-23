module LessonAttendances
  class AutomaticSweep
    CATCH_UP_WINDOW = 1.day

    def initialize(actor:, now: Time.current, relation: ScheduledLesson.all)
      @actor = actor
      @now = now
      @relation = relation
    end

    def call
      due_lessons.find_each { |lesson| process_lesson(lesson) }
    end

    private

    def due_lessons
      threshold = AcademySetting.current.absence_after_minutes.minutes
      @relation.where(status: %w[scheduled in_progress])
               .where(starts_at: (@now - CATCH_UP_WINDOW)..(@now - threshold))
               .includes(:lesson_attendances, :scheduled_lesson_enrollments)
    end

    def process_lesson(lesson)
      start_lesson(lesson) if lesson.scheduled?
      return unless lesson.in_progress?

      Initialize.new(actor: @actor, lesson:).call!
      lesson.lesson_attendances.unresolved.find_each do |attendance|
        MarkAbsent.new(actor: @actor, attendance:, override: true, reason: "automatic_attendance_sweep").call!
      end
    end

    def start_lesson(lesson)
      LessonOperations::Start.new(actor: @actor, lesson:, override: true,
                                  reason: "automatic_attendance_sweep").call
    end
  end
end
