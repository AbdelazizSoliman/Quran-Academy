require "rails_helper"

RSpec.describe "Parent portal" do
  let(:guardian_user) { create(:user, :guardian, preferred_locale: "en") }
  let!(:guardian) { create(:guardian, user: guardian_user, email: guardian_user.email) }
  let!(:linked_student) { create(:student_profile, display_name: "Linked Student") }
  let!(:unlinked_student) { create(:student_profile, display_name: "Private Student") }

  before do
    create(:student_guardianship, guardian:, student_profile: linked_student, status: "active")
    sign_in guardian_user
  end

  it "renders the guardian dashboard and navigation" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Linked Student", guardian_students_path, guardian_reports_path)
    expect(response.body).not_to include("Private Student", admin_students_path)
    expect(response.body).not_to include("translation missing")
  end

  it "shows only linked students" do
    get guardian_students_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Linked Student")
    expect(response.body).not_to include("Private Student")

    get guardian_student_path(unlinked_student)
    expect(response).to have_http_status(:not_found)
  end

  it "shows only published four-measure evaluations for linked children" do
    admin = create(:user, :admin)
    teacher = create(:teacher_profile, :active)
    enrollment = create(:enrollment, :active, student_profile: linked_student)
    template = Assessments::MadarakTemplate.ensure!(actor: admin)
    published = StudentAssessments::Create.new(
      actor: admin,
      attributes: {
        enrollment:, teacher_profile: teacher, assessment_template: template, assessment_date: Date.current
      },
      category_scores: {
        memorization: "excellent", tajweed: "very_good", attendance: "good", behavior: "fair"
      }
    ).call
    published.update!(status: "published")
    draft = create(:student_assessment, enrollment:, student_profile: linked_student,
                                        teacher_profile: teacher, assessment_template: template, assessment_date: Date.new(2000, 1, 1),
                                        status: "draft")
    private_assessment = create(:student_assessment, student_profile: unlinked_student,
                                                     enrollment: create(:enrollment, student_profile: unlinked_student),
                                                     status: "published")

    get guardian_reports_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(published.student_profile.display_name)
    %w[memorization tajweed attendance behavior].each do |code|
      expect(response.body).to include(I18n.t("madarak_evaluations.fields.#{code}", locale: :en))
    end
    expect(response.body).not_to include(draft.assessment_date.to_s, private_assessment.student_profile.display_name)
  end

  it "shows attendance and reports for a fee-plan-only (direct-participation) linked child" do
    direct_child = create(:student_profile, display_name: "Direct Child")
    create(:student_guardianship, guardian:, student_profile: direct_child, status: "active")
    lesson = create(:scheduled_lesson, status: "completed", course_offering: nil, started_at: 1.hour.ago,
                                       ended_at: Time.current, completed_at: Time.current,
                                       attendance_status: "locked")
    participant = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment: nil,
                                                       student_profile: direct_child)
    create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: participant, status: "present")
    report = LessonReports::Initialize.new(actor: lesson.teacher_profile.user, lesson:).call
    entry = report.lesson_student_reports.first
    report.update!(status: "reviewed")
    entry.update!(status: "completed")

    get guardian_attendances_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Direct Child")

    get guardian_reports_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Direct Child")
  end

  it "forbids non-guardian accounts" do
    sign_out guardian_user
    sign_in create(:user, :student)

    get guardian_students_path

    expect(response).to have_http_status(:forbidden)
  end

  it "requires authentication" do
    sign_out guardian_user

    get guardian_students_path

    expect(response).to redirect_to(new_user_session_path)
  end
end
