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

  it "offers a student evaluation action after the lesson is completed" do
    sign_in lesson.teacher_profile.user
    get teacher_schedule_report_path(lesson)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("academic.actions.evaluate_student"))
    evaluation_link = response.parsed_body.at_css("a[href^='/teacher/assessments/new']")
    expect(evaluation_link&.attr("href")).to eq(new_teacher_assessment_path(
                                                  enrollment_id: participant.enrollment_id,
                                                  student_profile_id: participant.student_profile.id,
                                                  scheduled_lesson_id: lesson.id
                                                ))
  end

  it "offers evaluation from a completed direct-student report" do
    student = create(:student_profile, :complete)
    direct_lesson = create(:scheduled_lesson, teacher_profile: lesson.teacher_profile, course_offering: nil,
                                              status: "completed", started_at: 1.hour.ago,
                                              ended_at: Time.current, completed_at: Time.current,
                                              attendance_status: "locked")
    participation = create(:scheduled_lesson_enrollment, scheduled_lesson: direct_lesson, enrollment: nil,
                                                          student_profile: student)
    create(:lesson_attendance, scheduled_lesson: direct_lesson, scheduled_lesson_enrollment: participation,
                               status: "present")
    report = LessonReports::Initialize.new(actor: direct_lesson.teacher_profile.user, lesson: direct_lesson).call
    report.lesson_student_reports.sole.update!(status: "completed")
    sign_in direct_lesson.teacher_profile.user

    get teacher_schedule_report_path(direct_lesson)

    expect(response).to have_http_status(:ok)
    link = response.parsed_body.at_css("a[href^='/teacher/assessments/new']")
    expect(link&.attr("href")).to eq(new_teacher_assessment_path(
                                      enrollment_id: nil, student_profile_id: student.id,
                                      scheduled_lesson_id: direct_lesson.id
                                    ))
  end

  it "continues an existing draft lesson evaluation instead of offering a duplicate" do
    report = initialized_report
    assessment = create(:student_assessment, teacher_profile: lesson.teacher_profile,
                                             enrollment: participant.enrollment,
                                             student_profile: participant.student_profile,
                                             scheduled_lesson: lesson)
    sign_in lesson.teacher_profile.user

    get teacher_schedule_report_path(lesson)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("academic.actions.continue_student_assessment", locale: :ar))
    expect(response.parsed_body.at_css("a[href='#{evaluate_teacher_assessment_path(assessment)}']")).to be_present
    expect(report).to be_persisted
  end

  it "shows the saved report details on the teacher report page" do
    report = initialized_report
    report.update!(lesson_summary: "Reading practice", topics_covered: "Surah Al-Fatihah",
                   general_homework: "Repeat five times", next_lesson_plan: "Start Al-Baqarah",
                   overall_engagement: "engaged", overall_progress: "meeting_expectations")
    report.lesson_student_reports.first.update!(status: "completed", strengths: "Clear pronunciation",
                                                homework: "Review the lesson")

    sign_in lesson.teacher_profile.user
    get teacher_schedule_report_path(lesson)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Reading practice", "Surah Al-Fatihah", "Repeat five times",
                                     "Start Al-Baqarah", "Clear pronunciation", "Review the lesson")
    expect(response.body).not_to include(I18n.t("communications.actions.student_whatsapp", locale: :ar))
  end

  it "does not offer manual WhatsApp delivery from the admin lesson report" do
    report = initialized_report
    sign_in admin

    get admin_lesson_report_path(report)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(I18n.t("communications.actions.student_whatsapp", locale: :ar))
    expect(response.body).not_to include(I18n.t("communications.actions.guardian_whatsapp", locale: :ar))
    expect(response.body).to include(I18n.t("communications.actions.student_email", locale: :ar))
  end

  it "explains pending student reports in Arabic before submission" do
    report = initialized_report
    report.update!(lesson_summary: "ملخص الدرس")
    teacher = lesson.teacher_profile.user
    teacher.update!(preferred_locale: "ar")
    sign_in teacher

    get teacher_schedule_report_path(lesson)
    expect(response.body).to include(I18n.t("lesson_reports.messages.complete_students_before_submit", locale: :ar))
    expect(response.body).not_to include(I18n.t("lesson_reports.actions.submit", locale: :ar))

    patch submit_teacher_schedule_report_path(lesson)
    expect(flash[:alert]).to include(I18n.t(
                                       "activerecord.errors.models.lesson_report.attributes.base.unresolved_entries",
                                       locale: :ar
                                     ))
    expect(flash[:alert]).not_to include("Translation missing")
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

  it "shows a fee-plan-only student their own direct-participation report" do
    profile = create(:student_profile, :complete)
    direct_lesson = create(:scheduled_lesson, status: "completed", course_offering: nil, started_at: 1.hour.ago,
                                              ended_at: Time.current, completed_at: Time.current,
                                              attendance_status: "locked")
    create(:scheduled_lesson_enrollment, scheduled_lesson: direct_lesson, enrollment: nil, student_profile: profile)
    report = LessonReports::Initialize.new(actor: direct_lesson.teacher_profile.user, lesson: direct_lesson).call
    entry = report.lesson_student_reports.first
    report.update!(status: "reviewed", lesson_summary: "Direct summary")
    entry.update!(status: "completed")

    sign_in profile.user
    get student_reports_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(direct_lesson.title_en)

    get student_report_path(entry)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Direct summary")
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
