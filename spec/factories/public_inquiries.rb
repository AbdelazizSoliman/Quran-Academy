FactoryBot.define do
  factory :public_inquiry do
    inquiry_type { "trial" }
    name { "Amina Hassan" }
    phone { "+201001234567" }
    preferred_locale { "en" }
    source { PublicInquiry::SOURCE }
    submitted_at { Time.current }

    trait :contact do
      inquiry_type { "contact" }
      email { "amina@example.test" }
      message { "I would like to learn more." }
    end
  end
end
