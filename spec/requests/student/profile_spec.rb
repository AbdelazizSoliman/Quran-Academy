require "rails_helper"

RSpec.describe "Student self-service profile" do
  let(:student_user) { create(:user, :student) }
  let!(:profile) do
    create(:student_profile, user: student_user, medical_notes: "Private medical",
                             safeguarding_notes: "Private safeguarding", internal_notes: "Private admin")
  end

  before { sign_in student_user }

  it "shows only safe current-student data in RTL and LTR" do
    student_user.update!(preferred_locale: "ar")
    get student_profile_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(profile.public_id, 'dir="rtl"')
    expect(response.body).not_to include("Private medical", "Private safeguarding", "Private admin")
    student_user.update!(preferred_locale: "en")
    get student_profile_path
    expect(response.body).to include('dir="ltr"')
  end

  it "updates allowed fields and rejects crafted protected fields" do
    patch student_profile_path, params: {
      student_profile: { display_name: "Self Updated", learning_status: "active",
                         medical_notes: "Exposed", profile_status: "verified", user_id: create(:user, :student).id }
    }
    profile.reload
    expect(profile.display_name).to eq("Self Updated")
    expect(profile.learning_status).to eq("prospective")
    expect(profile.medical_notes).to eq("Private medical")
    expect(profile.profile_status).to eq("draft")
  end

  it "shows onboarding when missing and limits a minor's guardian summary" do
    profile.destroy!
    student_user.association(:student_profile).reset
    get student_profile_path
    expect(response.body).to include(I18n.t("student.profile.missing.title", locale: :en))

    minor = create(:student_profile, :minor, user: student_user)
    guardian = create(:guardian, full_name: "Visible Guardian", email: "private.guardian@example.test")
    create(:student_guardianship, student_profile: minor, guardian:, relationship_type: "mother")
    get student_profile_path
    expect(response.body).to include("Visible Guardian")
    expect(response.body).not_to include("private.guardian@example.test")
  end

  it "forbids non-student roles" do
    sign_out student_user
    %i[staff teacher admin].each do |role|
      sign_in create(:user, role)
      get student_profile_path
      expect(response).to have_http_status(:forbidden)
      sign_out :user
    end
  end
end
