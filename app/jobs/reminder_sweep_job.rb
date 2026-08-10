class ReminderSweepJob < ApplicationJob
  queue_as :notifications

  def perform(actor: nil, now: Time.current)
    actor ||= User.find(ENV.fetch("NOTIFICATION_ACTOR_ID"))
    Notifications::LessonReminderScheduler.new(actor:, now:).call
  end
end
