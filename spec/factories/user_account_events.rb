FactoryBot.define do
  factory :user_account_event do
    association :target_user, factory: :user
    association :actor, factory: %i[user admin]
    event_type { "updated" }
    metadata { { "first_name" => { "from" => "Old", "to" => "New" } } }
  end
end
