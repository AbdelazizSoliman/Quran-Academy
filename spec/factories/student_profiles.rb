FactoryBot.define do
  factory :student_profile do
    association :user, factory: %i[user student]
    display_name { "Student #{Faker::Name.first_name}" }
    gender { "unspecified" }
    date_of_birth { 25.years.ago.to_date }
    country_of_residence { "EG" }
    preferred_contact_method { "email" }
    preferred_interface_locale { "en" }
    preferred_learning_language { "en" }
    current_quran_level { "beginner" }
    reading_level { "letters" }
    tajweed_level { "basic" }
    memorization_level { "short_surahs" }
    learning_goals { "Build confident Quran reading skills" }
    student_type { "adult" }
    profile_status { "draft" }
    learning_status { "prospective" }
    joined_on { Date.current }

    trait :minor do
      student_type { "minor" }
      date_of_birth { 10.years.ago.to_date }
      preferred_contact_method { "guardian" }
    end

    trait :complete do
      phone_number { "+201001234567" }
      profile_status { "complete" }
    end

    trait :archived do
      profile_status { "archived" }
    end
  end
end
