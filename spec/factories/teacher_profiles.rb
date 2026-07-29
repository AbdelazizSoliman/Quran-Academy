FactoryBot.define do
  factory :teacher_profile do
    association :user, factory: %i[user teacher]
    display_name { "Teacher Example" }
    bio { "Experienced Quran educator." }
    gender { "unspecified" }
    country_of_residence { "EG" }
    phone_number { "+201000000000" }
    highest_qualification { "Bachelor degree" }
    qualification_details { "Education and Quran studies" }
    years_of_teaching_experience { 8 }
    quran_teaching_experience_years { 6 }
    ijazah_status { "full" }
    teaching_languages { %w[ar] }
    student_age_groups { %w[children adults] }
    teaching_specializations { %w[quran_reading tajweed] }
    employment_status { "candidate" }
    engagement_type { "contractor" }
    profile_status { "draft" }
    joined_on { Date.current }
    default_lesson_rate { 100 }
    compensation_currency { "EGP" }
    compensation_unit { "per_lesson" }

    trait(:active) { employment_status { "active" } }
    trait(:complete) { profile_status { "complete" } }
    trait(:verified) { profile_status { "verified" } }
    trait(:archived) { profile_status { "archived" } }
  end
end
