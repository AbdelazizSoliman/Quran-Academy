class LateReminderSweepJob < ApplicationJob
  queue_as :notifications

  # Invoke once per minute alongside ReminderSweepJob. See README.md for the
  # scheduler command. This application does not install a scheduler.
  def perform(actor:, now: Time.current)
    Notifications::LateAttendanceReminderScheduler.new(actor:, now:).call
  end
end
