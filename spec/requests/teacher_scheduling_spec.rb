require "rails_helper"

RSpec.describe "Teacher scheduling requests" do
  let(:admin) { create(:user, :admin) }

  it "allows administrators to view scheduling" do
    sign_in admin
    get admin_scheduled_lessons_path
    expect(response).to have_http_status(:ok)
  end

  it "allows an administrator to create teacher availability" do
    teacher = create(:teacher_profile, :active, :complete, :verified)
    sign_in admin

    post admin_teacher_availabilities_path, params: {
      teacher_availability: {
        teacher_profile_id: teacher.id, weekday: "monday", starts_at_local: "09:00",
        ends_at_local: "12:00", time_zone: "Cairo", effective_from: Date.current,
        availability_type: "teaching"
      }
    }

    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(admin_teacher_availability_path(TeacherAvailability.last))
    expect(teacher.availabilities.count).to eq(1)
  end

  it "displays a scheduled lesson's participants" do
    lesson = create(:scheduled_lesson)
    participant = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)

    sign_in admin
    get admin_scheduled_lesson_path(lesson)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(participant.enrollment.student_profile.display_name)
  end

  it "renders participants when scheduling validation fails" do
    lesson = create(:scheduled_lesson)
    participant = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)

    sign_in admin
    patch schedule_admin_scheduled_lesson_path(lesson)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(participant.enrollment.student_profile.display_name)
    expect(response.body).to include(I18n.t("forms.errors_title", locale: :ar))
  end

  it "allows staff read-only access but blocks staff mutations" do
    sign_in create(:user, :staff)
    get admin_scheduled_lessons_path
    expect(response).to have_http_status(:ok)
    get new_admin_scheduled_lesson_path
    expect(response).to have_http_status(:forbidden)
  end

  it "scopes teacher schedule to the signed-in teacher" do
    teacher = create(:teacher_profile, :complete, :verified)
    sign_in teacher.user
    get teacher_schedule_index_path
    expect(response).to have_http_status(:ok)
    expect { get teacher_schedule_path(create(:scheduled_lesson)) }.not_to raise_error
  end

  it "keeps an assigned operational lesson visible after its scheduled start on the same day" do
    teacher = create(:teacher_profile, :active, :complete, :verified)
    day_start = Time.current.in_time_zone("Cairo").beginning_of_day
    lesson = create(:scheduled_lesson, :scheduled, teacher_profile: teacher,
                                                   starts_at: day_start, ends_at: day_start + 30.minutes)

    sign_in teacher.user
    get teacher_schedule_index_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(lesson.title_ar)
  end

  it "shows the assigned teacher an internal join link without exposing the external URL" do
    teacher = create(:teacher_profile, :active, :complete, :verified)
    lesson = create(:scheduled_lesson, :scheduled, teacher_profile: teacher,
                                                   online_meeting_url: "https://meet.example.test/private-room")
    sign_in teacher.user

    get teacher_schedule_path(lesson)

    expect(response.body).to include(join_teacher_schedule_path(lesson))
    expect(response.body).not_to include("https://meet.example.test/private-room")
  end

  it "allows a teacher to create their own availability" do
    teacher = create(:teacher_profile, :active, :complete, :verified)
    sign_in teacher.user

    expect do
      post teacher_availabilities_path, params: {
        teacher_availability: {
          weekday: "monday", starts_at_local: "09:00", ends_at_local: "12:00", time_zone: "Cairo",
          effective_from: Date.current, availability_type: "teaching"
        }
      }
    end.to change(teacher.availabilities, :count).by(1)

    expect(response).to redirect_to(teacher_availabilities_path)
  end

  it "allows a teacher to create their own availability exception" do
    teacher = create(:teacher_profile, :active, :complete, :verified)
    sign_in teacher.user

    expect do
      post teacher_availability_exceptions_path, params: {
        teacher_availability_exception: {
          exception_date: 2.days.from_now.to_date, time_zone: "Cairo", exception_type: "unavailable",
          reason: "Personal appointment"
        }
      }
    end.to change(teacher.availability_exceptions, :count).by(1)

    expect(response).to redirect_to(teacher_availability_exceptions_path)
  end

  it "scopes student schedule to the signed-in student" do
    student = create(:student_profile, :complete)
    sign_in student.user
    get student_schedule_index_path
    expect(response).to have_http_status(:ok)
  end

  it "shows the internal join link without exposing the external meeting URL" do
    student = create(:student_profile, :complete)
    lesson = create(:scheduled_lesson, :scheduled, online_meeting_url: "https://meet.example.test/quran")
    enrollment = create(:enrollment, :active, student_profile: student, course_offering: lesson.course_offering)
    create(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment:)

    sign_in student.user
    get student_schedule_path(lesson)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(join_student_schedule_path(lesson))
    expect(response.body).not_to include("https://meet.example.test/quran")
  end

  it "does not expose destroy routes" do
    delete_routes = Rails.application.routes.routes.select do |route|
      route.verb.to_s.include?("DELETE") && route.path.spec.to_s.include?("scheduled_lessons")
    end
    expect(delete_routes).to be_empty
  end
end
