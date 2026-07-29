FactoryBot.define do
  factory :academy_setting_event do
    academy_setting
    association :actor, factory: %i[user admin]
    event_type { "updated" }
    metadata { { "academy_name" => { "from" => "Old", "to" => "New" } } }
  end
end
