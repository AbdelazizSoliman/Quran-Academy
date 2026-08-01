FactoryBot.define do
  factory :lesson_report do
    association :scheduled_lesson
    teacher_profile { scheduled_lesson.teacher_profile }
    status { "draft" }
    report_language { "en" }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end

  factory :lesson_student_report do
    association :lesson_report
    scheduled_lesson_enrollment do
      association(:scheduled_lesson_enrollment, scheduled_lesson: lesson_report.scheduled_lesson)
    end
    status { "pending" }
    association :created_by, factory: %i[user admin]
    updated_by { created_by }
  end

  factory :communication_log do
    association :lesson_student_report
    scheduled_lesson { lesson_student_report.scheduled_lesson }
    lesson_report { lesson_student_report.lesson_report }
    student_profile { lesson_student_report.student_profile }
    recipient_user { student_profile.user }
    association :actor, factory: %i[user admin]
    channel { "email" }
    template_type { "student_progress" }
    recipient_address_masked { "s***@example.test" }
    recipient_locale { "en" }
    message_snapshot { "Safe progress message" }
    subject_snapshot { "Lesson update" }
    external_url { "mailto:student@example.test" }
    status { "prepared" }
    prepared_at { Time.current }
  end

  factory :lesson_report_event do
    association :lesson_report
    association :actor, factory: %i[user admin]
    event_type { "created" }
    before_data { {} }
    after_data { { "status" => "draft" } }
    metadata { {} }
  end
end
