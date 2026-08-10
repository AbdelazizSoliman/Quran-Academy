class NotificationAttemptJob < ApplicationJob
  queue_as :notifications

  def perform(notification:, actor:)
    Notifications::Attempt.new(notification:, actor:).call
  end
end
