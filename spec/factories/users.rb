FactoryBot.define do
  factory :user do
    sequence(:email) { |number| "user#{number}@example.test" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { "SecurePass123!" }
    password_confirmation { password }
    role { :staff }
    status { :active }
    preferred_locale { "ar" }
    time_zone { "Cairo" }

    trait(:admin) { role { :admin } }
    trait(:staff) { role { :staff } }
    trait(:teacher) { role { :teacher } }
    trait(:student) do
      role { :student }
      preferred_locale { "en" }
    end
    trait(:guardian) { role { :guardian } }

    trait(:active) { status { :active } }
    trait(:pending) { status { :pending } }
    trait(:suspended) { status { :suspended } }
    trait(:disabled) { status { :disabled } }
    trait(:arabic_locale) { preferred_locale { "ar" } }
    trait(:english_locale) { preferred_locale { "en" } }
    trait :with_sign_in_history do
      sign_in_count { 3 }
      current_sign_in_at { 1.hour.ago }
      last_sign_in_at { 1.day.ago }
      current_sign_in_ip { "192.0.2.10" }
      last_sign_in_ip { "192.0.2.9" }
    end
    trait :approved do
      status { :active }
      approved_at { 1.day.ago }
      association :approved_by, factory: %i[user admin]
    end
  end
end
