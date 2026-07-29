FactoryBot.define do
  factory :student_guardianship_event do
    student_guardianship
    association :actor, factory: %i[user admin]
    event_type { "updated" }
    metadata { {} }
  end
end
