module EnrollmentLessonSchedules
  class GenerationSweep
    def initialize(actor:, through_date: nil)
      @actor = actor
      @through_date = through_date
    end

    def call
      EnrollmentLessonSchedule.active.includes(:slots).find_each.map do |schedule|
        GenerateOccurrences.new(schedule:, actor: @actor, through_date: @through_date).call
      end
    end
  end
end
