FactoryBot.define do
  factory :fee_plan do
    sequence(:name) { |number| "Fee Plan #{number}" }
    amount { 500 }
    currency { "EGP" }
    billing_cycle { "monthly" }
    tax_percentage { 0 }
    invoice_day { 7 }
    active { true }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }

    trait(:inactive) { active { false } }

    trait :published do
      published { true }
      sequence(:name_ar) { |number| "خطة الرسوم #{number}" }
      sequence(:name_en) { |number| "Public Fee Plan #{number}" }
      description_ar { "خطة شهرية للمتعلمات." }
      description_en { "A monthly plan for learners." }
      public_features_ar { "حصص منتظمة\nمتابعة أسبوعية" }
      public_features_en { "Regular lessons\nWeekly follow-up" }
    end
  end
end
