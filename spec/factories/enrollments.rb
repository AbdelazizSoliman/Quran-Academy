FactoryBot.define do
  factory :enrollment do
    association :student_profile, :complete
    association :course_offering, :open
    status { "pending" }
    application_source { "administrator" }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }

    trait(:approved) { status { "approved" } }
    trait(:active) { status { "active" } }
    trait :completed do
      status { "completed" }
      exit_reason { "completed_program" }
      ended_on { Date.current }
    end
  end
end
