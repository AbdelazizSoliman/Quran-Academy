require "rails_helper"

RSpec.describe "Teacher scheduling requests" do
  let(:admin) { create(:user, :admin) }

  it "allows administrators to view scheduling" do
    sign_in admin
    get admin_scheduled_lessons_path
    expect(response).to have_http_status(:ok)
  end

  it "renders the new scheduled lesson form with eligible teachers, offerings, and students" do
    teacher = create(:teacher_profile, :active, :verified)
    offering = create(:course_offering, :open)
    student = create(:student_profile, :complete)
    sign_in admin

    get new_admin_scheduled_lesson_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(teacher.display_name, offering.title_en, student.display_name)
    expect(response.body).to include(I18n.t("scheduling.fields.online_meeting_url", locale: :ar))
    expect(response.body).to include(I18n.t("scheduling.catalogs.lesson_types.direct_student", locale: :ar))
  end

  it "creates a direct student lesson with no course offering, program, or enrollment" do
    teacher = create(:teacher_profile, :active, :verified, online_meeting_url: "https://meet.example.test/teacher")
    student = create(:student_profile, :complete)
    sign_in admin
    starts_at = 1.day.from_now.change(hour: 10, min: 0)

    expect do
      post admin_scheduled_lessons_path, params: {
        scheduled_lesson: {
          lesson_type: "direct_student", teacher_profile_id: teacher.id, student_profile_id: student.id,
          title_ar: "درس مباشر", title_en: "Direct lesson", academy_time_zone: "Cairo",
          starts_at: starts_at.strftime("%Y-%m-%dT%H:%M"), ends_at: (starts_at + 30.minutes).strftime("%Y-%m-%dT%H:%M"),
          delivery_mode: "online"
        }
      }
    end.to change(ScheduledLesson, :count).by(1)

    lesson = ScheduledLesson.last
    expect(response).to redirect_to(admin_scheduled_lesson_path(lesson))
    expect(lesson.course_offering_id).to be_nil
    expect(lesson.teacher_profile).to eq(teacher)
    participation = lesson.scheduled_lesson_enrollments.sole
    expect(participation.enrollment_id).to be_nil
    expect(participation.student_profile).to eq(student)
    expect(Enrollment.count).to eq(0)
    expect(CourseOffering.count).to eq(0)
  end

  it "rejects creating a direct student lesson without selecting a student" do
    teacher = create(:teacher_profile, :active, :verified)
    sign_in admin
    starts_at = 1.day.from_now.change(hour: 10, min: 0)

    expect do
      post admin_scheduled_lessons_path, params: {
        scheduled_lesson: {
          lesson_type: "direct_student", teacher_profile_id: teacher.id, student_profile_id: "",
          title_ar: "درس مباشر", title_en: "Direct lesson", academy_time_zone: "Cairo",
          starts_at: starts_at.strftime("%Y-%m-%dT%H:%M"), ends_at: (starts_at + 30.minutes).strftime("%Y-%m-%dT%H:%M"),
          delivery_mode: "online"
        }
      }
    end.not_to change(ScheduledLesson, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "still creates a course-offering lesson through the same form" do
    teacher = create(:teacher_profile, :active, :verified)
    offering = create(:course_offering, :open)
    sign_in admin
    starts_at = 1.day.from_now.change(hour: 10, min: 0)

    expect do
      post admin_scheduled_lessons_path, params: {
        scheduled_lesson: {
          lesson_type: "course_offering", course_offering_id: offering.id, teacher_profile_id: teacher.id,
          title_ar: "درس عرض", title_en: "Offering lesson", academy_time_zone: "Cairo",
          starts_at: starts_at.strftime("%Y-%m-%dT%H:%M"), ends_at: (starts_at + 30.minutes).strftime("%Y-%m-%dT%H:%M"),
          delivery_mode: "online"
        }
      }
    end.to change(ScheduledLesson, :count).by(1)

    lesson = ScheduledLesson.last
    expect(lesson.course_offering).to eq(offering)
    expect(lesson.scheduled_lesson_enrollments).to be_empty
  end

  it "still enforces teacher availability when scheduling a manually-created direct lesson" do
    teacher = create(:teacher_profile, :active, :verified, online_meeting_url: "https://meet.example.test/teacher")
    student = create(:student_profile, :complete)
    sign_in admin
    starts_at = 1.day.from_now.change(hour: 10, min: 0)

    post admin_scheduled_lessons_path, params: {
      scheduled_lesson: {
        lesson_type: "direct_student", teacher_profile_id: teacher.id, student_profile_id: student.id,
        title_ar: "درس", title_en: "Lesson", academy_time_zone: "Cairo",
        starts_at: starts_at.strftime("%Y-%m-%dT%H:%M"), ends_at: (starts_at + 30.minutes).strftime("%Y-%m-%dT%H:%M"),
        delivery_mode: "online"
      }
    }
    lesson = ScheduledLesson.last

    patch schedule_admin_scheduled_lesson_path(lesson)

    expect(response).to have_http_status(:unprocessable_content)
    expect(lesson.reload).to be_draft
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

  it "labels the lesson URL as an optional override and shows the assigned teacher default on edit" do
    teacher = create(:teacher_profile, :active, :verified,
                     online_meeting_url: "https://meet.example.test/teacher-default")
    lesson = create(:scheduled_lesson, teacher_profile: teacher, online_meeting_url: nil)
    sign_in admin

    get edit_admin_scheduled_lesson_path(lesson)

    expect(response.body).to include(I18n.t("scheduling.fields.online_meeting_url", locale: :ar))
    expect(response.body).to include(I18n.t("scheduling.online_meeting_url_override_hint", locale: :ar))
    expect(response.body).to include("https://meet.example.test/teacher-default")
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

  it "renders the selected Sunday-to-Saturday week as a seven-day calendar" do
    selected_day = Date.new(2026, 8, 12)
    week_start = selected_day.beginning_of_week(:sunday)
    inside = create(:scheduled_lesson, title_ar: "Inside week", title_en: "Inside week", starts_at: week_start.noon,
                                       ends_at: week_start.noon + 45.minutes)
    outside = create(:scheduled_lesson, title_ar: "Outside week", title_en: "Outside week", starts_at: (week_start + 7.days).noon,
                                        ends_at: (week_start + 7.days).noon + 45.minutes)
    sign_in admin

    get admin_scheduled_lessons_path(week: selected_day.iso8601)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("grid-cols-7", inside.title_ar)
    expect(response.body).not_to include(outside.title_ar)
    expect(response.body).to include((week_start - 7.days).iso8601, (week_start + 7.days).iso8601)
  end

  it "filters the weekly calendar by teacher, offering, and status" do
    week_start = Date.new(2026, 8, 9)
    teacher = create(:teacher_profile, :active, :verified)
    offering = create(:course_offering, :open)
    matching = create(:scheduled_lesson, :scheduled, title_ar: "Matching lesson", title_en: "Matching lesson", teacher_profile: teacher, course_offering: offering,
                                                     starts_at: week_start.noon, ends_at: week_start.noon + 45.minutes)
    other = create(:scheduled_lesson, title_ar: "Other lesson", title_en: "Other lesson", starts_at: (week_start + 1.day).noon,
                                      ends_at: (week_start + 1.day).noon + 45.minutes)
    sign_in admin

    get admin_scheduled_lessons_path(
      week: week_start.iso8601,
      teacher_profile_id: teacher.id,
      course_offering_id: offering.id,
      status: "scheduled"
    )

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(matching.title_ar, teacher.display_name, offering.title_en)
    expect(response.body).not_to include(other.title_ar)
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
