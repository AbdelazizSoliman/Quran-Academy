require "rails_helper"

RSpec.describe "Admin student learning profiles" do
  let(:admin) { create(:user, :admin) }
  let(:student) { create(:student_profile) }

  before { sign_in admin }

  it "renders an empty profile without persisting it" do
    expect { get admin_student_learning_profile_path(student, locale: "ar", section: "language_cultural_background") }
      .not_to change(StudentLearningProfile, :count)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("الملف التعليمي", 'dir="rtl"')
    expect(response.body).to include("اللغات المستخدمة", "الاعتبارات الثقافية", "الأساسية: 0 من 7 مكتملة")
  end

  it "creates the profile and saves a section through domain services" do
    expect do
      patch admin_student_learning_profile_section_path(student, "basic_information"), params: {
        section: { completion_state: "in_progress" },
        items: { instructional_summary: "Needs short recitation practice" }
      }
    end.to change(StudentLearningProfile, :count).by(1)
    expect(response).to redirect_to(admin_student_learning_profile_path(student, section: "basic_information"))
    expect(student.student_learning_profile.items.pluck(:field_key)).to include("instructional_summary")
  end

  it "allows an admin to mark a section reviewed" do
    patch admin_student_learning_profile_section_path(student, "basic_information"), params: {
      section: { completion_state: "complete", review_state: "reviewed" }
    }
    section = student.student_learning_profile.sections.find_by!(section_key: "basic_information")
    expect(section.reviewed_by).to eq(admin)
    expect(section.reviewed_at).to be_present
    get admin_student_learning_profile_path(student)
    expect(response.body).to include("المراجعة")
  end
end
