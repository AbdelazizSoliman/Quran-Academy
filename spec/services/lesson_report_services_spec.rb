require "rails_helper"

RSpec.describe "Lesson report services" do
  let(:admin) { create(:user, :admin) }
  let(:lesson) do
    create(:scheduled_lesson, status: "completed", started_at: 1.hour.ago, ended_at: Time.current,
                              completed_at: Time.current, attendance_status: "locked")
  end
  let(:teacher) { lesson.teacher_profile.user }
  let!(:participant) { create(:scheduled_lesson_enrollment, scheduled_lesson: lesson) }
  let!(:attendance) do
    create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: participant, status: "present")
  end

  it "initializes a report and participant entry idempotently" do
    report = LessonReports::Initialize.new(actor: teacher, lesson:).call
    expect(report.lesson_student_reports.size).to eq(1)
    expect { LessonReports::Initialize.new(actor: teacher, lesson:).call }.not_to change(LessonReport, :count)
  end

  it "uses attendance to make absence not applicable" do
    attendance.update!(status: "absent")
    report = LessonReports::Initialize.new(actor: teacher, lesson:).call
    expect(report.lesson_student_reports.first).to be_not_applicable
  end

  it "updates draft content and creates no audit for a no-op" do
    report = initialized_report
    LessonReports::Update.new(actor: teacher, report:, attributes: { lesson_summary: "Reading practice" }).call
    expect(report.lesson_summary).to eq("Reading practice")
    expect do
      LessonReports::Update.new(actor: teacher, report:, attributes: { lesson_summary: "Reading practice" }).call
    end.not_to change(LessonReportEvent, :count)
  end

  it "blocks submission until summary and entries are resolved" do
    report = initialized_report
    expect(LessonReports::Submit.new(actor: teacher, report:).call.errors).to be_present
    report.errors.clear
    report.update!(lesson_summary: "Completed reading")
    expect(LessonReports::Submit.new(actor: teacher, report:).call.errors).to be_present
    report.lesson_student_reports.first.update!(status: "completed")
    report.errors.clear
    LessonReports::Submit.new(actor: teacher, report:).call
    expect(report).to be_submitted
  end

  it "rejects submission before attendance is locked" do
    report = initialized_report
    report.update!(lesson_summary: "Completed", status: "draft")
    report.lesson_student_reports.each { |entry| entry.update!(status: "completed") }
    lesson.update!(attendance_status: "open")
    expect(LessonReports::Submit.new(actor: teacher, report:).call.errors).to be_present
  end

  it "supports administrator review, lock, reopen with reason, and relock" do
    report = submitted_report
    Admin::LessonReports::Transition.new(actor: admin, report:, action: :review).call
    expect(report).to be_reviewed
    Admin::LessonReports::Transition.new(actor: admin, report:, action: :lock).call
    expect(report).to be_locked
    expect(Admin::LessonReports::Reopen.new(actor: admin, report:, reason: nil).call.errors).to be_present
    report.errors.clear
    Admin::LessonReports::Reopen.new(actor: admin, report:, reason: "Correction needed").call
    expect(report).to be_reopened
    Admin::LessonReports::Transition.new(actor: admin, report:, action: :relock).call
    expect(report).to be_locked
  end

  it "allows only the assigned teacher to update student content and masks private audit values" do
    entry = initialized_report.lesson_student_reports.first
    result = LessonStudentReports::Update.new(actor: create(:user, :teacher), entry:,
                                              attributes: { status: "completed" }).call
    expect(result.errors).to be_present
    entry.errors.clear
    LessonStudentReports::Update.new(actor: teacher, entry:,
                                     attributes: { status: "completed", private_teacher_notes: "Internal" }).call
    event = entry.events.last
    expect(event.metadata).to eq("private_notes_changed" => true)
    expect(event.after_data.to_s).not_to include("Internal")
  end

  it "reserves withholding a student entry for administrators" do
    entry = initialized_report.lesson_student_reports.first
    result = LessonStudentReports::Update.new(actor: teacher, entry:, attributes: { status: "withheld" }).call
    expect(result.errors).to be_present
    expect(entry).to be_pending
  end

  private

  def initialized_report
    LessonReports::Initialize.new(actor: teacher, lesson:).call
  end

  def submitted_report
    report = initialized_report
    report.update!(lesson_summary: "Complete report")
    report.lesson_student_reports.each { |entry| entry.update!(status: "completed") }
    LessonReports::Submit.new(actor: teacher, report:).call
  end
end
