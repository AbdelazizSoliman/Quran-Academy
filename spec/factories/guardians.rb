FactoryBot.define do
  factory :guardian do
    sequence(:full_name) { |n| "Guardian #{n}" }
    sequence(:email) { |n| "guardian#{n}@example.test" }
    gender { "unspecified" }
    preferred_contact_method { "email" }
    preferred_language { "ar" }
    status { "active" }
  end
end
