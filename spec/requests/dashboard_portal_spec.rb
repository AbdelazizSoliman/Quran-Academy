require "rails_helper"

RSpec.describe "Dashboard portal lesson actions" do
  it "labels completed teacher lessons as details instead of open lesson" do
    teacher = create(:teacher_profile, :active, :verified)
    completed = create(:scheduled_lesson, teacher_profile: teacher, status: "completed",
                                          starts_at: Time.current.beginning_of_day + 1.hour,
                                          ends_at: Time.current.beginning_of_day + 2.hours,
                                          started_at: Time.current.beginning_of_day + 1.hour,
                                          ended_at: Time.current.beginning_of_day + 2.hours,
                                          completed_at: Time.current.beginning_of_day + 2.hours,
                                          attendance_status: "locked")
    active = create(:scheduled_lesson, teacher_profile: teacher, status: "in_progress",
                                       starts_at: Time.current.beginning_of_day + 3.hours,
                                       ends_at: Time.current.beginning_of_day + 4.hours,
                                       started_at: Time.current.beginning_of_day + 3.hours,
                                       attendance_status: "open")
    sign_in teacher.user

    get root_path

    document = response.parsed_body
    expect(document.at_css("a[href='#{teacher_schedule_path(completed)}']")&.text&.strip)
      .to eq(I18n.t("portal.actions.lesson_details"))
    expect(document.at_css("a[href='#{teacher_schedule_path(active)}']")&.text&.strip)
      .to eq(I18n.t("portal.actions.open_lesson"))
  end
end
