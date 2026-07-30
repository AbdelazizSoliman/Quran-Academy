FactoryBot.define do
  factory :course_offering do
    association :program, :active
    sequence(:code) { |number| "OFR_#{number}" }
    title_ar { "عرض القرآن" }
    title_en { "Quran Offering" }
    status { "draft" }
    learning_language { "en" }
    delivery_mode { "online" }
    target_age_groups { %w[children teenagers adults seniors] }
    planned_start_on { 1.week.from_now.to_date }
    planned_end_on { 13.weeks.from_now.to_date }
    default_lesson_duration_minutes { 30 }
    intended_lessons_per_week { 2 }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }

    trait :open do
      status { "open" }
      accepts_new_enrollments { true }
    end

    trait :placement_required do
      placement_required { true }
    end
  end
end
