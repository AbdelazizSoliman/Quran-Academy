require "rails_helper"

RSpec.describe "Admin students" do
  let(:admin) { create(:user, :admin) }
  let(:student_user) { create(:user, :student) }

  before { sign_in admin }

  it "lists, searches, and renders both directions" do
    profile = create(:student_profile, user: student_user, display_name: "Search Learner")
    get admin_students_path, params: { q: "Search", locale: "ar" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(profile.public_id, 'dir="rtl"')
    get admin_students_path, params: { locale: "en" }
    expect(response.body).to include('dir="ltr"')
  end

  it "creates, updates, verifies, archives, and restores with audits" do
    post admin_students_path, params: {
      student_profile: attributes_for(:student_profile).except(:user).merge(user_id: student_user.id)
    }
    profile = student_user.reload.student_profile
    expect(response).to redirect_to(admin_student_path(profile))
    patch admin_student_path(profile), params: { student_profile: { display_name: "Updated Student" } }
    patch verify_admin_student_path(profile)
    expect(profile.reload.profile_status).to eq("verified")
    patch archive_admin_student_path(profile)
    expect(profile.reload.profile_status).to eq("archived")
    patch restore_admin_student_path(profile)
    expect(profile.reload.profile_status).to eq("draft")
    expect(profile.events.count).to eq(5)
  end

  it "rejects non-student ownership and duplicate profiles" do
    teacher = create(:user, :teacher)
    post admin_students_path, params: {
      student_profile: attributes_for(:student_profile).except(:user).merge(user_id: teacher.id)
    }
    expect(response).to have_http_status(:unprocessable_content)
    create(:student_profile, user: student_user)
    post admin_students_path, params: {
      student_profile: attributes_for(:student_profile).except(:user).merge(user_id: student_user.id)
    }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "excludes ownership, public IDs, lifecycle status, actors, and metadata from strong parameters" do
    profile = create(:student_profile, user: student_user)
    other = create(:user, :student)
    patch admin_student_path(profile), params: {
      student_profile: { display_name: "Allowed", user_id: other.id, public_id: "STD-HACKED0000",
                         profile_status: "verified", updated_by_id: other.id, metadata: { password: "x" } }
    }
    profile.reload
    expect(profile.user).to eq(student_user)
    expect(profile.public_id).not_to eq("STD-HACKED0000")
    expect(profile.profile_status).to eq("draft")
  end

  it "redirects unauthenticated users and forbids non-admin roles" do
    sign_out admin
    get admin_students_path
    expect(response).to redirect_to(new_user_session_path)
    %i[staff teacher student].each do |role|
      sign_in create(:user, role)
      get admin_students_path
      expect(response).to have_http_status(:forbidden)
      sign_out :user
    end
  end
end
