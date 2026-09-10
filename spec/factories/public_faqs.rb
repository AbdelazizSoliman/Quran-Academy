FactoryBot.define do
  factory :public_faq do
    sequence(:question_ar) { |number| "سؤال #{number}" }
    sequence(:question_en) { |number| "Question #{number}" }
    answer_ar { "إجابة واضحة" }
    answer_en { "A clear answer" }
    published { false }
    public_display_order { 0 }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }

    trait(:published) { published { true } }
  end
end
