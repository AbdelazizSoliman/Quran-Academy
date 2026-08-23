require "rails_helper"

RSpec.describe "Teacher reports" do
  it "renders current-month metrics for a teacher with lesson reports" do
    teacher = create(:teacher_profile, :active, :verified)
    lesson = create(:scheduled_lesson, teacher_profile: teacher, starts_at: Time.current)
    create(:lesson_report, scheduled_lesson: lesson, teacher_profile: teacher,
                           status: "submitted", created_by: teacher.user, updated_by: teacher.user)
    sign_in teacher.user

    get teacher_reports_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("reports.teacher.metrics.submitted_reports"), ">1<")
  end

  it "renders zero metrics for a teacher account whose profile has not been created yet" do
    teacher = create(:user, :teacher)
    sign_in teacher

    get teacher_reports_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("translation missing")
  end
end
