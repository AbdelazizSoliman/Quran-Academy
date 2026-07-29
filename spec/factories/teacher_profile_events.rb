FactoryBot.define do
  factory :teacher_profile_event do
    teacher_profile
    association :actor, factory: %i[user admin]
    event_type { "updated" }
    metadata { { "changes" => { "display_name" => { "from" => "Old", "to" => "New" } } } }
  end
end
