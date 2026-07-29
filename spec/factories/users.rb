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

    trait(:active) { status { :active } }
    trait(:pending) { status { :pending } }
    trait(:suspended) { status { :suspended } }
    trait(:disabled) { status { :disabled } }
    trait(:arabic_locale) { preferred_locale { "ar" } }
    trait(:english_locale) { preferred_locale { "en" } }
  end
end
