require "rails_helper"

RSpec.describe "Student schedule" do
  let(:teacher) do
    create(:teacher_profile, :active, :verified, online_meeting_url: "https://meet.example.test/teacher")
  end
  let(:profile) { create(:student_profile, :complete) }

  def direct_lesson(starts_at: 1.day.from_now.change(hour: 10))
    lesson = create(:scheduled_lesson, :scheduled, course_offering: nil, teacher_profile: teacher, starts_at:,
                                                   ends_at: starts_at + 45.minutes,
                                                   online_meeting_url: "https://meet.example.test/lesson")
    create(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment: nil, student_profile: profile)
    lesson
  end

  before { sign_in profile.user }

  it "lists a direct-participation lesson on the schedule index" do
    lesson = direct_lesson

    get student_schedule_index_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(lesson.title_en)
  end

  it "shows a direct-participation lesson without a course offering" do
    lesson = direct_lesson

    get student_schedule_path(lesson)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(lesson.public_id)
  end

  it "allows the correct student to join a direct-participation lesson" do
    lesson = direct_lesson(starts_at: Time.current)
    lesson.update!(status: "in_progress", started_at: Time.current, attendance_status: "open",
                   attendance_opened_at: Time.current)

    get join_student_schedule_path(lesson)

    expect(response).to redirect_to("https://meet.example.test/lesson")
    expect(lesson.lesson_attendances.sole.student_profile).to eq(profile)
  end

  it "does not expose another student's direct-participation lesson" do
    lesson = direct_lesson
    other = create(:student_profile, :complete)
    sign_in other.user

    get student_schedule_path(lesson)

    expect(response).to have_http_status(:not_found)
  end
end
