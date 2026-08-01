FactoryBot.define do
  factory :lesson_attendance do
    association :scheduled_lesson_enrollment
    scheduled_lesson { scheduled_lesson_enrollment.scheduled_lesson }
    status { "pending" }
    minutes_late { 0 }
  end

  factory :lesson_attendance_event do
    association :lesson_attendance
    association :actor, factory: %i[user admin]
    event_type { "initialized" }
    before_data { {} }
    after_data { { "status" => "pending" } }
    metadata { {} }
  end
end
