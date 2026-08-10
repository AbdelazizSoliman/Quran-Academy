class LateReminderSweepJob < ApplicationJob
  queue_as :notifications

  def perform(actor: nil, now: Time.current)
    actor ||= User.find(ENV.fetch("NOTIFICATION_ACTOR_ID"))
    Notifications::LateAttendanceReminderScheduler.new(actor:, now:).call
  end
end
