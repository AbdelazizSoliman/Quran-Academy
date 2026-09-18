require "rails_helper"

RSpec.describe "Teacher student learning profiles" do
  let(:teacher_user) { create(:user, :teacher) }
  let!(:teacher) { create(:teacher_profile, :active, :verified, user: teacher_user) }
  let(:student) { create(:student_profile, assigned_teacher_profile: teacher) }

  before do
    teacher_user.update!(preferred_locale: "en")
    sign_in teacher_user
  end

  it "allows an assigned teacher to view and update instructional content" do
    get teacher_student_learning_profile_path(student, locale: "en", section: "language_cultural_background")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Learning Profile", 'dir="ltr"')
    expect(response.body).to include("Spoken languages", "Cultural considerations", "Required: 0 of 7 complete")
    expect(response.body).not_to include("Review")

    patch teacher_student_learning_profile_section_path(student, "basic_information"), params: {
      section: { completion_state: "in_progress", review_state: "reviewed" },
      items: { instructional_summary: "Likes examples" }
    }
    expect(response).to redirect_to(teacher_student_learning_profile_path(student, section: "basic_information"))
    expect(student.student_learning_profile.items.find_by(field_key: "instructional_summary").value).to eq("Likes examples")
  end

  it "denies an unassigned teacher" do
    other = create(:student_profile)
    get teacher_student_learning_profile_path(other)
    expect(response).to have_http_status(:not_found)
  end

  it "creates an observation without exposing edit or delete controls" do
    post teacher_student_observations_path(student), params: {
      observation: { category: "attention", observation: "Stayed engaged throughout the lesson" }
    }
    expect(response).to redirect_to(teacher_student_learning_profile_path(student))
    expect(student.student_observations.count).to eq(1)
    get teacher_student_learning_profile_path(student)
    expect(response.body).to include("Stayed engaged throughout the lesson")
    expect(response.body).not_to include("Delete", "تعديل")
  end
end
