FactoryBot.define do
  factory :public_testimonial do
    author_name { "Parent A." }
    relationship { "Parent" }
    quote_ar { "تجربة تعليمية طيبة" }
    quote_en { "A thoughtful learning experience" }
    published { false }
    public_display_order { 0 }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }

    trait(:published) { published { true } }
  end
end
