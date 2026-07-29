FactoryBot.define do
  factory :academy_setting do
    singleton_key { "current" }
    academy_name { "Quran Academy" }

    trait :english_default do
      default_locale { "en" }
      supported_locales { %w[ar en] }
    end

    trait :limited_working_week do
      working_days { %w[sunday monday tuesday] }
    end

    trait :communications_enabled do
      whatsapp_notifications_enabled { true }
      sms_notifications_enabled { true }
    end

    trait :finance_configured do
      default_teacher_rate { 250 }
      default_lesson_price { 300 }
      payroll_currency { "EGP" }
      billing_currency { "EGP" }
    end
  end
end
