FactoryBot.define do
  factory :guardian_event do
    guardian
    association :actor, factory: %i[user admin]
    event_type { "updated" }
    metadata { {} }
  end
end
