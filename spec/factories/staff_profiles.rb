FactoryBot.define do
  factory :staff_profile do
    association :user, factory: %i[user staff]
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
    display_name { user.full_name }
    phone_number { "+201001234567" }
    whatsapp_number { phone_number }
  end
end
