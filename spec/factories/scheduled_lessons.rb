FactoryBot.define do
  factory :scheduled_lesson do
    association :course_offering, :open
    association :teacher_profile, factory: %i[teacher_profile active verified]
    title_ar { "درس القرآن" }
    title_en { "Quran lesson" }
    starts_at { 2.days.from_now.change(hour: 10, min: 0) }
    ends_at { 2.days.from_now.change(hour: 11, min: 0) }
    academy_time_zone { "Cairo" }
    delivery_mode { "online" }
    online_meeting_url { "https://example.test/lesson" }
    status { "draft" }
    scheduling_source { "manual" }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }

    trait(:scheduled) { status { "scheduled" } }
    trait(:in_progress) do
      status { "in_progress" }
      started_at { Time.current }
      attendance_status { "open" }
      attendance_opened_at { Time.current }
    end
  end

  factory :scheduled_lesson_enrollment do
    association :scheduled_lesson
    enrollment { association(:enrollment, :approved, course_offering: scheduled_lesson.course_offering) }
    participation_status { "expected" }
    association :added_by, factory: %i[user admin]
  end
end
