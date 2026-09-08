require "rails_helper"

RSpec.describe "Academic progress administration" do
  let(:admin) { create(:user, :admin) }

  it "allows admin management and staff read-only access" do
    sign_in admin
    get admin_student_assessments_path
    expect(response).to have_http_status(:ok)
    get admin_exam_sessions_path
    expect(response).to have_http_status(:ok)
    get admin_academic_dashboard_path
    expect(response).to have_http_status(:ok)

    sign_out admin
    sign_in create(:user, :staff)
    get admin_student_assessments_path
    expect(response).to have_http_status(:ok)
    get new_admin_student_assessment_path
    expect(response).to have_http_status(:forbidden)
  end

  it "creates a complete four-measure Madarak evaluation in one step" do
    enrollment = create(:enrollment, :active)
    teacher = create(:teacher_profile, :active, :verified)
    sign_in admin

    expect do
      post admin_student_assessments_path, params: {
        student_assessment: {
          enrollment_id: enrollment.id,
          teacher_profile_id: teacher.id,
          assessment_date: Date.current,
          notes: "Weekly review"
        },
        quick_scores: {
          memorization: "excellent",
          tajweed: "very_good",
          attendance: "good",
          behavior: "fair"
        }
      }
    end.to change(StudentAssessment, :count).by(1)

    assessment = StudentAssessment.last
    expect(response).to redirect_to(admin_student_assessment_path(assessment))
    expect(assessment.status).to eq("draft")
    expect(assessment.overall_score).to eq(80)
    expect(assessment.scores.includes(assessment_rubric_item: :assessment_category)
                     .to_h { |score| [score.assessment_rubric_item.assessment_category.code, score.rating] })
      .to eq("memorization" => "excellent", "tajweed" => "very_good",
             "attendance" => "good", "behavior" => "fair")
  end

  it "shows the Madarak evaluation columns and filters" do
    assessment = create(:student_assessment)
    sign_in admin

    get admin_student_assessments_path

    expect(response).to have_http_status(:ok)
    %i[student memorization tajweed attendance behavior overall date status actions].each do |field|
      expect(response.body).to include(I18n.t("madarak_evaluations.fields.#{field}", locale: :ar))
    end
    expect(response.body).to include(assessment.student_profile.display_name)
    expect(response.body).to include('name="student_id"', 'name="teacher_id"', 'name="status"')
  end
  it "does not expose destructive routes" do
    paths = %w[/admin/student_assessments/1 /admin/exam_sessions/1 /admin/certificates/1
               /admin/assessment_templates/1 /admin/assessment_categories/1]
    paths.each do |path|
      expect { Rails.application.routes.recognize_path(path, method: :delete) }
        .to raise_error(ActionController::RoutingError)
    end
  end
end

RSpec.describe "Teacher academic progress access" do
  it "isolates assessments and exams to the assigned teacher" do
    teacher = create(:teacher_profile, :active)
    other = create(:student_assessment)
    own = create(:student_assessment, teacher_profile: teacher)
    sign_in teacher.user

    get teacher_assessment_path(own)
    expect(response).to have_http_status(:ok)
    get teacher_assessment_path(other)
    expect(response).to have_http_status(:not_found)
  end
end

RSpec.describe "Student academic records" do
  it "shows completed records to the student while keeping drafts private" do
    student = create(:student_profile)
    published = create(:student_assessment, student_profile: student,
                                            enrollment: create(:enrollment, student_profile: student), status: "published")
    draft = create(:student_assessment, student_profile: student,
                                        enrollment: create(:enrollment, student_profile: student), status: "draft")
    submitted = create(:student_assessment, student_profile: student,
                                            enrollment: create(:enrollment, student_profile: student),
                                            status: "submitted")
    student.user.update!(preferred_locale: "ar")
    sign_in student.user

    get student_assessments_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(published.public_id)
    expect(response.body).to include(submitted.public_id)
    expect(response.body).to include(I18n.l(published.assessment_date, locale: :ar))
    expect(response.body).not_to include(draft.public_id)
    get student_assessment_path(draft)
    expect(response).to have_http_status(:not_found)
    get student_assessment_path(submitted)
    expect(response).to have_http_status(:ok)
  end

  it "provides a personal transcript and progress page" do
    student = create(:student_profile)
    sign_in student.user
    get student_transcript_path
    expect(response).to have_http_status(:ok)
    get student_progress_path
    expect(response).to have_http_status(:ok)
  end
end
