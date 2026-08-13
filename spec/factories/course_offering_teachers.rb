FactoryBot.define do
  factory :course_offering_teacher do
    association :course_offering
    association :teacher_profile, factory: %i[teacher_profile active verified]
    association :created_by, factory: %i[user admin]
  end
end
