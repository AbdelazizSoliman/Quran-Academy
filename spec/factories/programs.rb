FactoryBot.define do
  factory :program do
    sequence(:code) { |number| "PRG_#{number}" }
    name_ar { "برنامج القرآن" }
    name_en { "Quran Program" }
    short_description_ar { "برنامج لتعلّم القرآن خطوة بخطوة." }
    short_description_en { "A step by step Quran learning program." }
    category { "quran_reading" }
    status { "draft" }
    default_learning_language { "en" }
    supported_learning_languages { %w[ar en] }
    target_age_groups { %w[children teenagers adults seniors] }
    entry_level { "beginner" }
    completion_level { "intermediate" }
    default_lesson_duration_minutes { 30 }
    recommended_lessons_per_week { 2 }
    estimated_duration_weeks { 12 }
    allows_minor_students { true }
    allows_adult_students { true }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }

    trait(:active) { status { "active" } }
    trait(:placement_required) { requires_placement { true } }

    trait :published do
      status { "active" }
      published { true }
      sequence(:slug_ar) { |number| "برنامج-القرآن-#{number}" }
      sequence(:slug_en) { |number| "quran-program-#{number}" }
    end

    trait(:featured) { public_featured { true } }
  end
end
