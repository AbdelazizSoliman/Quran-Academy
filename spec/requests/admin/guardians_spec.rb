require "rails_helper"

RSpec.describe "Admin guardians and relationships" do
  let(:admin) { create(:user, :admin) }
  let(:student) { create(:student_profile, :minor) }

  before { sign_in admin }

  it "manages guardians without creating user accounts or deleting history" do
    expect do
      post admin_guardians_path, params: { guardian: attributes_for(:guardian) }
    end.to change(Guardian, :count).by(1)
    guardian = Guardian.last
    patch admin_guardian_path(guardian), params: { guardian: { city: "Cairo" } }
    expect(guardian.reload.city).to eq("Cairo")
    patch archive_admin_guardian_path(guardian)
    expect(guardian.reload).to be_archived
    patch restore_admin_guardian_path(guardian)
    expect(guardian.reload.status).to eq("active")
  end

  it "attaches, switches primary, and ends a relationship non-destructively" do
    first = create(:guardian)
    second = create(:guardian)
    post admin_student_guardianships_path(student), params: {
      student_guardianship: { guardian_id: first.id, relationship_type: "father" }
    }
    first_link = student.student_guardianships.last
    patch make_primary_admin_student_guardianship_path(student, first_link)
    post admin_student_guardianships_path(student), params: {
      student_guardianship: { guardian_id: second.id, relationship_type: "mother" }
    }
    second_link = student.student_guardianships.order(:id).last
    patch make_primary_admin_student_guardianship_path(student, second_link)
    expect(first_link.reload).not_to be_primary_contact
    patch end_admin_student_guardianship_path(student, first_link)
    expect(first_link.reload.status).to eq("ended")
    expect(StudentGuardianship.exists?(first_link.id)).to be(true)
  end

  it "forbids staff, teachers, and students" do
    sign_out admin
    %i[staff teacher student].each do |role|
      sign_in create(:user, role)
      get admin_guardians_path
      expect(response).to have_http_status(:forbidden)
      sign_out :user
    end
  end
end
