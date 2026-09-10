FactoryBot.define do
  factory :public_legal_page do
    page_type { "privacy" }
    title_ar { "سياسة الخصوصية" }
    title_en { "Privacy Policy" }
    body_ar { "نص سياسة الخصوصية." }
    body_en { "Privacy policy text." }
    published { false }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }

    trait(:published) { published { true } }
  end
end
