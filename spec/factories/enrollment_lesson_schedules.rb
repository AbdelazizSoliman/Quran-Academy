FactoryBot.define do
  factory :enrollment_lesson_schedule do
    association :enrollment, :approved
    association :teacher_profile, factory: %i[teacher_profile active verified]
    starts_on { Date.current }
    ends_on { nil }
    lesson_duration_minutes { 45 }
    time_zone { "Cairo" }
    status { "active" }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end

  factory :enrollment_lesson_schedule_slot do
    enrollment_lesson_schedule
    weekday { "monday" }
    starts_at_local { "18:00" }
    position { 0 }
  end
end
