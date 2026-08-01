FactoryBot.define do
  factory :teacher_payroll do
    association :teacher_profile, :active, :verified
    period_starts_on { Date.current.beginning_of_month }
    period_ends_on { Date.current.end_of_month }
    calculation_strategy { "per_lesson" }
    currency { "EGP" }
    rate { 100 }
    base_amount { 200 }
    net_amount { 200 }
    status { "draft" }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end

  factory :teacher_payroll_item do
    association :teacher_payroll
    scheduled_lesson do
      association(:scheduled_lesson, status: "completed", teacher_profile: teacher_payroll.teacher_profile,
                                     starts_at: 1.hour.ago, ends_at: Time.current)
    end
    duration_minutes { 60 }
    rate { teacher_payroll.rate }
    amount { rate }
  end

  factory :teacher_payroll_event do
    association :teacher_payroll
    association :actor, factory: %i[user admin]
    event_type { "generated" }
    before_data { {} }
    after_data { { "status" => "draft" } }
    metadata { {} }
  end
end
