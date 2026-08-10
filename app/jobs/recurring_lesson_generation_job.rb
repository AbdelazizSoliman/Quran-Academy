class RecurringLessonGenerationJob < ApplicationJob
  queue_as :default

  def perform(actor: nil, through_date: nil)
    actor ||= User.find(ENV.fetch("SCHEDULING_ACTOR_ID"))
    EnrollmentLessonSchedules::GenerationSweep.new(actor:, through_date:).call
  end
end
