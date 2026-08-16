require "rails_helper"

RSpec.describe "Student and guardian navigation" do
  it "shows student management while temporarily hiding guardian management from admins" do
    sign_in create(:user, :admin)
    get root_path
    expect(response.body).to include(%(href="#{admin_students_path}"))
    expect(response.body).not_to include(%(href="#{admin_guardians_path}"))
  end

  it "shows My Profile to students without admin links" do
    sign_in create(:user, :student)
    get root_path
    expect(response.body).to include(student_profile_path)
    expect(response.body).not_to include(admin_students_path, admin_guardians_path)
  end

  it "does not expose student management to staff or teachers" do
    %i[staff teacher].each do |role|
      sign_in create(:user, role)
      get root_path
      expect(response.body).not_to include(admin_students_path, admin_guardians_path)
      sign_out :user
    end
  end
end
