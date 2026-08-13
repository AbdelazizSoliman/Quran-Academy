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
  end
end
