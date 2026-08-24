require "rails_helper"

RSpec.describe "Teacher assessments" do
  let(:teacher) do
    create(:teacher_profile, :active, :verified,
           user: create(:user, :teacher, status: "active"))
  end

  before { sign_in teacher.user }

  it "renders the new assessment form using the aliased teacher route" do
    get new_teacher_assessment_path

    expect(response).to have_http_status(:ok)
    document = response.parsed_body
    expect(document.at_css("form")&.attr("action")).to eq(teacher_assessments_path)
    template = AssessmentTemplate.find_by!(name_en: Assessments::MadarakTemplate::NAME_EN)
    template_field = document.at_css("input[name='student_assessment[assessment_template_id]']")
    expect(template_field&.attr("value")).to eq(template.id.to_s)
    Assessments::MadarakTemplate::CATEGORIES.each_key do |code|
      expect(document.at_css("select[name='quick_scores[#{code}]']")).to be_present
    end
  end

  it "prefills the student and lesson when evaluating after a completed lesson" do
    lesson = create(:scheduled_lesson, teacher_profile: teacher, status: "completed",
                                       started_at: 1.hour.ago, ended_at: Time.current,
                                       completed_at: Time.current, attendance_status: "locked")
    participant = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)

    get new_teacher_assessment_path(enrollment_id: participant.enrollment_id, scheduled_lesson_id: lesson.id)

    expect(response).to have_http_status(:ok)
    document = response.parsed_body
    expect(document.at_css("input[name='student_assessment[enrollment_id]']")&.attr("value"))
      .to eq(participant.enrollment_id.to_s)
    expect(document.at_css("input[name='student_assessment[scheduled_lesson_id]']")&.attr("value"))
      .to eq(lesson.id.to_s)
    expect(response.body).to include(I18n.t("academic.actions.evaluate_student", locale: :ar))
    expect(response.body).not_to include(I18n.t("academic.actions.edit_assessment", locale: :ar))
  end

  it "opens an owned draft directly in the continue-evaluation form" do
    assessment = create(:student_assessment, teacher_profile: teacher)

    get evaluate_teacher_assessment_path(assessment)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("academic.actions.continue_student_assessment", locale: :ar))
    expect(response.body).not_to include(I18n.t("academic.actions.edit_assessment", locale: :ar))
    expect(response.parsed_body.at_css("form")&.attr("action")).to eq(teacher_assessment_path(assessment))
  end

  it "does not let a teacher evaluate another teacher's assessment" do
    other_assessment = create(:student_assessment)

    get evaluate_teacher_assessment_path(other_assessment)

    expect(response).to have_http_status(:not_found)
  end

  it "creates and lists an assessment for a direct private-lesson student" do
    student = create(:student_profile, :complete)
    lesson = create(:scheduled_lesson, teacher_profile: teacher, course_offering: nil, status: "completed",
                                       started_at: 1.hour.ago, ended_at: Time.current,
                                       completed_at: Time.current, attendance_status: "locked")
    create(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment: nil, student_profile: student)
    get new_teacher_assessment_path(student_profile_id: student.id, scheduled_lesson_id: lesson.id)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(student.display_name)
    template = AssessmentTemplate.find_by!(name_en: Assessments::MadarakTemplate::NAME_EN)

    expect do
      post teacher_assessments_path, params: {
        student_assessment: { student_profile_id: student.id, scheduled_lesson_id: lesson.id,
                              assessment_template_id: template.id, assessment_date: Date.current },
        quick_scores: { memorization: "excellent", tajweed: "very_good", attendance: "good",
                        behavior: "fair" }
      }
    end.to change(StudentAssessment, :count).by(1)

    assessment = StudentAssessment.last
    expect(assessment.student_profile).to eq(student)
    expect(assessment.enrollment).to be_nil
    expect(assessment.overall_score).to eq(80)
    get teacher_assessments_path
    expect(response.body).to include(assessment.public_id)
  end
end
