FactoryBot.define do
  factory :notification do
    association :recipient_user, factory: %i[user student]
    association :actor, factory: %i[user admin]
    channel { "email" }
    provider { "resend" }
    notification_type { "certificate" }
    status { "pending" }
    recipient_address_masked { "s***@example.test" }
    recipient_locale { "en" }
    subject { "Quran Academy notification" }
    message_snapshot { "Safe notification content" }
  end

  factory :notification_event do
    notification
    actor { notification.actor }
    event_type { "created" }
  end

  factory :notification_attempt do
    notification
    actor { notification.actor }
    attempt_number { 1 }
    provider { notification.provider }
    status { "sent" }
    recipient_address_masked { notification.recipient_address_masked }
    request_fingerprint { Digest::SHA256.hexdigest("safe-request") }
    attempted_at { Time.current }
    completed_at { Time.current }
  end
end
