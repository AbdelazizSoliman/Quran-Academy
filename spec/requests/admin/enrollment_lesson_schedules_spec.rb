require "rails_helper"

RSpec.describe "Admin enrollment recurring lesson schedules" do
  let(:admin) { create(:user, :admin) }
  let!(:teacher) { create(:teacher_profile, :active, :verified) }
  let(:enrollment) { create(:enrollment, :approved) }

  before { sign_in admin }

  it "renders enrollment-level schedule management" do
    get new_admin_enrollment_lesson_schedule_path(enrollment)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(teacher.display_name)
    expect(response.body).to include(I18n.t("recurring_schedules.fields.slots", locale: :ar))
  end

  it "creates an unlimited row-based slot schedule from line input" do
    post admin_enrollment_lesson_schedules_path(enrollment), params: {
      enrollment_lesson_schedule: {
        teacher_profile_id: teacher.id, starts_on: Date.current, lesson_duration_minutes: 45,
        time_zone: "Cairo", status: "active",
        slots_text: "sunday 18:00\ntuesday 18:00\nthursday 19:30\nsaturday 08:00"
      }
    }

    schedule = enrollment.lesson_schedules.last
    expect(response).to redirect_to(admin_enrollment_lesson_schedule_path(enrollment, schedule))
    expect(schedule.slots.count).to eq(4)
  end

  it "shows persistent generation issues and upcoming generated lessons" do
    schedule = create(:enrollment_lesson_schedule, enrollment:, teacher_profile: teacher)
    slot = create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule)
    EnrollmentLessonGenerationIssue.create!(enrollment_lesson_schedule_slot: slot,
                                            recurrence_date: Date.current, reason_code: "teacher_unavailable")

    get admin_enrollment_lesson_schedule_path(enrollment, schedule)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("teacher_unavailable")
  end
end
