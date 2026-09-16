FactoryBot.define do
  factory :student_learning_profile do
    association :student_profile
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end

  factory :student_learning_profile_section do
    student_learning_profile
    section_key { "educational_quranic_background" }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end

  factory :student_learning_profile_item do
    association :section, factory: :student_learning_profile_section
    field_key { "educational_background_notes" }
    value { "Learns well through short demonstrations" }
    value_type { nil }
    sensitivity { nil }
    visibility { nil }
    source { "teacher_entry" }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end

  factory :student_learning_profile_event do
    student_learning_profile
    association :actor, factory: %i[user admin]
    action { "profile_created" }
    source { "admin_entry" }
  end

  factory :student_observation do
    student_profile
    association :teacher_profile, :active, :verified
    created_by { teacher_profile.user }
    category { "engagement" }
    observation { "Responded well to a short recitation demonstration." }
    observed_at { Time.current }
    visibility { "internal" }
    sensitivity { "standard" }
    source { "teacher_entry" }
  end
end
