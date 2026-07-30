FactoryBot.define do
  factory :program_event do
    program
    association :actor, factory: %i[user admin]
    event_type { "created" }
    metadata { {} }
  end

  factory :course_offering_event do
    course_offering
    association :actor, factory: %i[user admin]
    event_type { "created" }
    metadata { {} }
  end

  factory :enrollment_event do
    enrollment
    association :actor, factory: %i[user admin]
    event_type { "created" }
    metadata { {} }
  end
end
