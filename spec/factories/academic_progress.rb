FactoryBot.define do
  factory :assessment_category do
    sequence(:code) { |number| AssessmentCategory::CODES[(number - 1) % AssessmentCategory::CODES.length] }
    sequence(:name_ar) { |number| "فئة #{number}" }
    sequence(:name_en) { |number| "Category #{number}" }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end

  factory :assessment_template do
    sequence(:name_ar) { |number| "تقييم #{number}" }
    sequence(:name_en) { |number| "Assessment #{number}" }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end

  factory :assessment_rubric_item do
    assessment_template
    assessment_category
    sequence(:name_ar) { |number| "بند #{number}" }
    sequence(:name_en) { |number| "Rubric #{number}" }
    scoring_type { "numeric" }
    maximum_score { 100 }
    weight { 1 }
  end

  factory :student_assessment do
    enrollment
    student_profile { enrollment.student_profile }
    teacher_profile
    assessment_template
    assessment_date { Date.current }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end

  factory :assessment_score do
    student_assessment
    assessment_rubric_item { association :assessment_rubric_item, assessment_template: student_assessment.assessment_template }
    numeric_score { 80 }
  end

  factory :student_progress do
    student_profile
    trend { "stable" }
  end

  factory :exam_session do
    program
    course_offering { association :course_offering, program: }
    teacher_profile
    title { "Monthly Quran Exam" }
    starts_at { 1.week.from_now }
    duration_minutes { 60 }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end

  factory :certificate do
    student_profile
    enrollment { association :enrollment, student_profile: }
    certificate_type { "program_completion" }
    issued_on { Date.current }
    association :issuer, factory: %i[user admin]
  end
end
