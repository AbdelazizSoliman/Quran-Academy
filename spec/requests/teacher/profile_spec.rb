require "rails_helper"

RSpec.describe "Teacher self-service profile" do
  before { AcademySetting.current.update!(teaching_languages: %w[ar en]) }

  let(:teacher_user) { create(:user, :teacher) }
  let!(:profile) { create(:teacher_profile, user: teacher_user, internal_notes: "Private", default_lesson_rate: 100) }

  it "allows an active teacher to view only their own safe profile" do
    sign_in teacher_user
    get teacher_profile_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(profile.display_name, profile.public_id)
    expect(response.body).not_to include("Private", "100.0", "translation missing")
  end

  it "updates only self-service fields despite crafted administrative parameters" do
    sign_in teacher_user
    patch teacher_profile_path, params: {
      teacher_profile: {
        display_name: "Self Updated", internal_notes: "Exposed", default_lesson_rate: 999,
        employment_status: "departed", profile_status: "verified", public_id: "HACK",
        teaching_languages: %w[en], teaching_specializations: %w[tajweed],
        student_age_groups: %w[adults]
      }
    }

    expect(response).to redirect_to(teacher_profile_path)
    expect(profile.reload.attributes.values_at(
             "display_name", "internal_notes", "default_lesson_rate", "employment_status", "profile_status", "public_id"
           )).to eq(["Self Updated", "Private", BigDecimal("100"), "candidate", "draft", profile.public_id])
    expect(profile.events.last.event_type).to eq("self_updated")
  end

  it "gracefully renders onboarding for a teacher without a profile" do
    profile.destroy!
    teacher_user.association(:teacher_profile).reset
    sign_in teacher_user
    get teacher_profile_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("إعداد الملف قيد الانتظار")
  end

  it "renders English LTR from the teacher preference" do
    teacher_user.update!(preferred_locale: "en")
    sign_in teacher_user
    get teacher_profile_path
    expect(response.body).to include('lang="en"', 'dir="ltr"', "My Profile")
  end

  it "forbids admin, staff, and student from teacher self-service" do
    %i[admin staff student].each do |role|
      sign_in create(:user, role)
      get teacher_profile_path
      expect(response).to have_http_status(:forbidden)
      sign_out :user
    end
  end

  it "does not expose another teacher through an identifier route" do
    other = create(:teacher_profile)
    sign_in teacher_user
    get "/teacher/profiles/#{other.id}"
    expect(response).to have_http_status(:not_found)
  end
end
