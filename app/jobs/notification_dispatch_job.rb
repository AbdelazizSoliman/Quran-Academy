class NotificationDispatchJob < ApplicationJob
  queue_as :notifications

  def perform(actor:, recipient:, source:, notification_type:, channel:, **options)
    Notifications::Dispatch.new(actor:, recipient:, source:, type: notification_type, channel:, **options).call
  end
end
