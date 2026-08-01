FactoryBot.define do
  factory :teacher_availability_exception do
    association :teacher_profile, factory: %i[teacher_profile active complete verified]
    exception_date { Date.current + 2.days }
    time_zone { "Cairo" }
    exception_type { "unavailable" }
    status { "active" }
    reason { "Personal appointment" }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end
end
