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
      expect(document.at_css("input[type='number'][name='quick_scores[#{code}]']")).to be_present
    end
  end

  it "shows the evaluation form and recent lesson evaluations in one workspace" do
    assessment = create(:student_assessment, teacher_profile: teacher, overall_score: 85)

    get teacher_assessments_path

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("#new-evaluation form")).to be_present
    expect(response.body).to include(assessment.student_profile.display_name)
  end

  it "accepts exact numeric scores in the teacher evaluation form" do
    lesson = create(:scheduled_lesson, teacher_profile: teacher, status: "completed",
                                       completed_at: Time.current, attendance_status: "locked")
    participant = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
    template = Assessments::MadarakTemplate.ensure!(actor: teacher.user)

    post teacher_assessments_path, params: {
      student_assessment: { student_profile_id: participant.student_profile.id,
                            scheduled_lesson_id: lesson.id, assessment_template_id: template.id,
                            assessment_date: Date.current },
      quick_scores: { memorization: 90, tajweed: 80, attendance: 70, behavior: 60 }
    }

    assessment = StudentAssessment.find_by!(scheduled_lesson: lesson)
    expect(assessment.scores.where.not(numeric_score: nil).count).to eq(4)
    expect(response).to redirect_to(teacher_assessment_path(assessment))
    expect(assessment.overall_score).to eq(75)
    expect(assessment.scores.pluck(:numeric_score)).to contain_exactly(90, 80, 70, 60)
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
    assessment.scores.each do |score|
      field = response.parsed_body.at_css("input[name='scores[#{score.id}][lock_version]']")
      expect(field&.attr("value")).to eq(score.lock_version.to_s)
    end
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

  it "moves through the eligible lesson students without evaluating absences" do
    lesson = create(:scheduled_lesson, teacher_profile: teacher, status: "completed",
                                       completed_at: Time.current, attendance_status: "locked")
    first = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
    second = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
    absent = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
    create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: first, status: "present")
    create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: second, status: "late")
    create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: absent, status: "absent")
    template = Assessments::MadarakTemplate.ensure!(actor: teacher.user)

    get evaluations_teacher_schedule_path(lesson)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("academic.lesson_evaluations.progress", completed: 0, total: 2))

    post teacher_assessments_path, params: {
      lesson_queue: 1, flow_action: "next",
      student_assessment: { student_profile_id: first.student_profile.id,
                            scheduled_lesson_id: lesson.id, assessment_template_id: template.id,
                            assessment_date: Date.current },
      quick_scores: { memorization: 90, tajweed: 80, attendance: 70, behavior: 60 }
    }

    expect(response).to redirect_to(new_teacher_assessment_path(
                                      scheduled_lesson_id: lesson.id,
                                      student_profile_id: second.student_profile.id,
                                      lesson_queue: 1
                                    ))
  end

  it "resumes an existing lesson draft instead of creating a duplicate" do
    lesson = create(:scheduled_lesson, teacher_profile: teacher, status: "completed",
                                       completed_at: Time.current, attendance_status: "locked")
    participant = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
    template = Assessments::MadarakTemplate.ensure!(actor: teacher.user)
    assessment = create(:student_assessment, teacher_profile: teacher, enrollment: participant.enrollment,
                                             student_profile: participant.student_profile,
                                             scheduled_lesson: lesson, assessment_template: template)

    expect do
      post teacher_assessments_path, params: {
        student_assessment: { student_profile_id: participant.student_profile.id,
                              scheduled_lesson_id: lesson.id, assessment_template_id: template.id,
                              assessment_date: Date.current },
        quick_scores: { memorization: 90, tajweed: 80, attendance: 70, behavior: 60 }
      }
    end.not_to change(StudentAssessment, :count)

    expect(response).to redirect_to(evaluate_teacher_assessment_path(assessment, lesson_queue: 1))
  end

  it "submits all complete lesson drafts together" do
    lesson = create(:scheduled_lesson, teacher_profile: teacher, status: "completed",
                                       completed_at: Time.current, attendance_status: "locked")
    participant = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
    create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: participant,
                               status: "present")
    template = Assessments::MadarakTemplate.ensure!(actor: teacher.user)
    post teacher_assessments_path, params: {
      lesson_queue: 1,
      student_assessment: { student_profile_id: participant.student_profile.id,
                            scheduled_lesson_id: lesson.id, assessment_template_id: template.id,
                            assessment_date: Date.current },
      quick_scores: { memorization: 90, tajweed: 80, attendance: 70, behavior: 60 }
    }
    assessment = StudentAssessment.find_by!(scheduled_lesson: lesson)
    expect(assessment.scores.where.not(numeric_score: nil).count).to eq(4)

    patch submit_evaluations_teacher_schedule_path(lesson)

    expect(response).to redirect_to(evaluations_teacher_schedule_path(lesson))
    expect(flash[:alert]).to be_nil
    expect(assessment.reload).to be_submitted
  end
end
