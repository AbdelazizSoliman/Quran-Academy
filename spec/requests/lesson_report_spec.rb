require "rails_helper"

RSpec.describe "Lesson report requests" do
  let(:admin) { create(:user, :admin) }
  let(:lesson) do
    create(:scheduled_lesson, status: "completed", started_at: 1.hour.ago, ended_at: Time.current,
                              completed_at: Time.current, attendance_status: "locked")
  end
  let!(:participant) { create(:scheduled_lesson_enrollment, scheduled_lesson: lesson) }
  let(:attendance) do
    create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: participant, status: "present")
  end

  before { attendance }

  it "lets the assigned teacher initialize and edit a report but scopes other teachers out" do
    sign_in lesson.teacher_profile.user
    get teacher_schedule_report_path(lesson)
    expect(response).to have_http_status(:ok)
    report = lesson.reload.lesson_report
    patch teacher_schedule_report_path(lesson), params: { lesson_report: { lesson_summary: "Reading practice" } }
    expect(report.reload.lesson_summary).to eq("Reading practice")

    sign_out lesson.teacher_profile.user
    sign_in create(:teacher_profile, :active, :verified).user
    get teacher_schedule_report_path(lesson)
    expect(response).to have_http_status(:not_found)
  end

  it "lets administrators review, lock, and reopen" do
    report = submitted_report
    sign_in admin
    patch review_admin_lesson_report_path(report)
    expect(report.reload).to be_reviewed
    patch lock_admin_lesson_report_path(report)
    expect(report.reload).to be_locked
    patch reopen_admin_lesson_report_path(report), params: { reason: "Correct academic entry" }
    expect(report.reload).to be_reopened
  end

  it "keeps staff read-only" do
    report = submitted_report
    sign_in create(:user, :staff)
    get admin_lesson_report_path(report)
    expect(response).to have_http_status(:ok)
    patch lock_admin_lesson_report_path(report)
    expect(response).to have_http_status(:forbidden)
  end

  it "shows a student only their own finalized entry and hides private notes" do
    report = initialized_report
    entry = report.lesson_student_reports.first
    report.update!(status: "reviewed", lesson_summary: "Safe summary")
    entry.update!(status: "completed", private_teacher_notes: "Internal only", homework: "Revise")
    sign_in entry.student_profile.user
    get student_report_path(entry)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Safe summary", "Revise")
    expect(response.body).not_to include("Internal only")
    get student_report_path(create(:lesson_student_report, status: "completed"))
    expect(response).to have_http_status(:not_found)
  end

  it "prepares and manually confirms a communication without claiming delivery on creation" do
    report = initialized_report
    entry = report.lesson_student_reports.first
    entry.student_profile.update!(whatsapp_number: "+1 202-555-0187")
    sign_in admin
    post admin_lesson_report_communications_path(report), params: {
      entry_id: entry.id, channel: "whatsapp", template_type: "student_progress", recipient_type: "student"
    }
    log = CommunicationLog.last
    expect(log).to be_prepared
    patch confirm_sent_admin_communication_log_path(log)
    expect(log.reload).to be_confirmed_sent
  end

  it "defines no destructive report or communication routes" do
    routes = Rails.application.routes.routes.select do |route|
      route.verb.to_s.include?("DELETE") && route.path.spec.to_s.match?(/lesson_report|student_report|communication/)
    end
    expect(routes).to be_empty
  end

  private

  def initialized_report
    LessonReports::Initialize.new(actor: lesson.teacher_profile.user, lesson:).call
  end

  def submitted_report
    report = initialized_report
    report.update!(lesson_summary: "Complete academic report")
    report.lesson_student_reports.each { |entry| entry.update!(status: "completed") }
    LessonReports::Submit.new(actor: lesson.teacher_profile.user, report:).call
  end
end
