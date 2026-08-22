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
  end

  it "prefills the student and lesson when evaluating after a completed lesson" do
    lesson = create(:scheduled_lesson, teacher_profile: teacher, status: "completed",
                                       started_at: 1.hour.ago, ended_at: Time.current,
                                       completed_at: Time.current, attendance_status: "locked")
    participant = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)

    get new_teacher_assessment_path(enrollment_id: participant.enrollment_id, scheduled_lesson_id: lesson.id)

    expect(response).to have_http_status(:ok)
    document = response.parsed_body
    expect(document.at_css("select[name='student_assessment[enrollment_id]'] option[selected]")&.attr("value"))
      .to eq(participant.enrollment_id.to_s)
    expect(document.at_css("input[name='student_assessment[scheduled_lesson_id]']")&.attr("value"))
      .to eq(lesson.id.to_s)
  end
end
