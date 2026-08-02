class ReminderSweepJob < ApplicationJob
  queue_as :notifications

  # Invoke once per minute from cron, a Render Cron Job, or a future recurring-job
  # configuration. See README.md for the scheduler command. The scheduler only
  # enqueues this adapter; eligibility and idempotency remain in the service.
  def perform(actor:, now: Time.current)
    Notifications::LessonReminderScheduler.new(actor:, now:).call
  end
end
