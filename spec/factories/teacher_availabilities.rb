FactoryBot.define do
  factory :teacher_availability do
    association :teacher_profile, factory: %i[teacher_profile active complete verified]
    weekday { "monday" }
    starts_at_local { "09:00" }
    ends_at_local { "12:00" }
    time_zone { "Cairo" }
    effective_from { Date.current }
    availability_type { "teaching" }
    status { "active" }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end
end
