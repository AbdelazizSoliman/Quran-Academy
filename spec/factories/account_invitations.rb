FactoryBot.define do
  factory :account_invitation do
    association :user, factory: %i[user pending]
    association :created_by, factory: %i[user admin]
    sequence(:token_digest) { |number| Digest::SHA256.hexdigest("invitation-token-#{number}") }
    status { "sent" }
    expires_at { 72.hours.from_now }
    sent_at { Time.current }
    last_sent_at { sent_at }
  end

  factory :account_invitation_event do
    account_invitation
    actor { account_invitation.created_by }
    event_type { "created" }
  end
end
