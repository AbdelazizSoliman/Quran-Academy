require "rails_helper"

RSpec.describe "Teacher profile navigation" do
  it "shows teacher administration only to administrators" do
    sign_in create(:user, :admin)
    get dashboard_path
    expect(response.body).to include(admin_teachers_path, I18n.t("navigation.teachers", locale: :ar))
  end

  it "shows My Profile to teachers, including teachers without a profile" do
    sign_in create(:user, :teacher)
    get dashboard_path
    expect(response.body).to include(teacher_profile_path, I18n.t("navigation.my_profile", locale: :ar))
    expect(response.body).not_to include(admin_teachers_path)
  end

  %i[staff student].each do |role|
    it "does not show teacher links to #{role}" do
      sign_in create(:user, role)
      get dashboard_path
      expect(response.body).not_to include(admin_teachers_path, teacher_profile_path)
    end
  end

  it "marks teacher administration active" do
    sign_in create(:user, :admin)
    get admin_teachers_path
    expect(response.body).to include(%(href="#{admin_teachers_path}"), 'aria-current="page"')
  end
end
