class RecurringLessonGenerationJob < ApplicationJob
  queue_as :default

  def perform(actor:, through_date: nil)
    EnrollmentLessonSchedules::GenerationSweep.new(actor:, through_date:).call
  end
end
