require "rails_helper"

RSpec.describe "Lesson attendance requests" do
  let(:admin) { create(:user, :admin) }
  let(:lesson) { create(:scheduled_lesson, :in_progress, starts_at: 1.hour.ago, ends_at: 1.hour.from_now) }
  let!(:participant) { create(:scheduled_lesson_enrollment, scheduled_lesson: lesson) }
  let!(:attendance) { create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: participant) }

  it "allows admin and staff read-only review but only admin mutation" do
    sign_in admin
    get admin_lesson_attendances_path
    expect(response).to have_http_status(:ok)
    sign_out admin
    staff = create(:user, :staff)
    sign_in staff
    get attendance_admin_scheduled_lesson_path(lesson)
    expect(response).to have_http_status(:ok)
    patch mark_present_admin_scheduled_lesson_lesson_attendance_path(lesson, attendance)
    expect(response).to have_http_status(:forbidden)
  end

  it "allows assigned teacher operations and scopes another teacher out" do
    sign_in lesson.teacher_profile.user
    get attendance_teacher_schedule_path(lesson)
    expect(response).to have_http_status(:ok)
    patch mark_present_teacher_schedule_lesson_attendance_path(lesson, attendance)
    expect(response).to redirect_to(attendance_teacher_schedule_path(lesson))
    sign_out lesson.teacher_profile.user
    other = create(:teacher_profile, :active, :verified)
    sign_in other.user
    get attendance_teacher_schedule_path(lesson)
    expect(response).to have_http_status(:not_found)
  end

  it "shows students only their own attendance" do
    student = attendance.student_profile
    other_attendance = create(:lesson_attendance)
    sign_in student.user
    get student_attendances_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(attendance.scheduled_lesson.title_en)
    get student_attendance_path(other_attendance)
    expect(response).to have_http_status(:not_found)
  end

  it "shows a fee-plan-only student their own direct-participation attendance" do
    profile = create(:student_profile, :complete)
    direct_lesson = create(:scheduled_lesson, :in_progress, course_offering: nil, starts_at: 1.hour.ago,
                                                            ends_at: 1.hour.from_now)
    direct_participant = create(:scheduled_lesson_enrollment, scheduled_lesson: direct_lesson, enrollment: nil,
                                                              student_profile: profile)
    direct_attendance = create(:lesson_attendance, scheduled_lesson: direct_lesson,
                                                   scheduled_lesson_enrollment: direct_participant)

    sign_in profile.user
    get student_attendances_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(direct_lesson.title_en)

    get student_attendance_path(direct_attendance)
    expect(response).to have_http_status(:ok)
  end

  it "has no attendance destroy routes" do
    routes = Rails.application.routes.routes.select do |route|
      route.verb.to_s.include?("DELETE") && route.path.spec.to_s.match?(/attendance|lesson_attendance/)
    end
    expect(routes).to be_empty
  end
end
