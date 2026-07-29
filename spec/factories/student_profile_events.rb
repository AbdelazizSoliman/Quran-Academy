FactoryBot.define do
  factory :student_profile_event do
    student_profile
    association :actor, factory: %i[user admin]
    event_type { "updated" }
    metadata { {} }
  end
end
