FactoryBot.define do
  factory :finance_invoice do
    association :student_profile, :complete
    billing_period_starts_on { Date.current.beginning_of_month }
    billing_period_ends_on { Date.current.end_of_month }
    due_on { Date.current + 7.days }
    status { "draft" }
    currency { "EGP" }
    subtotal { 500 }
    discount_amount { 0 }
    tax_amount { 0 }
    total_amount { 500 }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }

    trait :issued do
      status { "issued" }
      issued_on { Date.current }
    end
  end

  factory :finance_payment do
    association :finance_invoice, :issued
    amount { 200 }
    currency { finance_invoice.currency }
    received_on { Date.current }
    payment_method { "bank_transfer" }
    status { "completed" }
    association :recorded_by, factory: %i[user admin]
  end

  factory :finance_expense do
    category { "technology" }
    description { "Video conferencing subscription" }
    amount { 100 }
    currency { "EGP" }
    incurred_on { Date.current }
    payment_method { "bank_transfer" }
    status { "draft" }
    association :created_by, factory: %i[user admin]
  end
end
