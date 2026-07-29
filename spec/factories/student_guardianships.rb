FactoryBot.define do
  factory :student_guardianship do
    student_profile
    guardian
    relationship_type { "legal_guardian" }
    status { "active" }
    starts_on { Date.current }
  end
end
