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
  it "shows only the student's published records and hides drafts" do
    student = create(:student_profile)
    published = create(:student_assessment, student_profile: student,
                                            enrollment: create(:enrollment, student_profile: student), status: "published")
    draft = create(:student_assessment, student_profile: student,
                                        enrollment: create(:enrollment, student_profile: student), status: "draft")
    sign_in student.user

    get student_assessments_path
    expect(response.body).to include(published.public_id)
    expect(response.body).not_to include(draft.public_id)
    get student_assessment_path(draft)
    expect(response).to have_http_status(:not_found)
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
