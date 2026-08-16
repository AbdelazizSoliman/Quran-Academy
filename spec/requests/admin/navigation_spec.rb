require "rails_helper"

RSpec.describe "Admin navigation" do
  it "shows only the currently enabled admin navigation links" do
    admin = create(:user, :admin)
    sign_in admin
    get root_path

    visible_paths = [
      root_path,
      admin_students_path,
      admin_teachers_path,
      admin_scheduled_lessons_path,
      admin_academic_dashboard_path,
      admin_fee_plans_path,
      admin_operational_reports_path
    ]
    hidden_paths = [admin_users_path, admin_account_invitations_path, admin_guardians_path, admin_settings_path]

    visible_paths.each { |path| expect(response.body).to include(%(href="#{path}")) }
    hidden_paths.each { |path| expect(response.body).not_to include(%(href="#{path}")) }
  end
end
