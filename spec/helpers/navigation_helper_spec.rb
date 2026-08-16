require "rails_helper"

RSpec.describe NavigationHelper do
  describe "WhatsApp navigation" do
    {
      admin: :admin_notifications_path,
      staff: :admin_notifications_path,
      teacher: :teacher_notifications_path,
      student: :student_notifications_path
    }.each do |role, route_helper|
      it "routes #{role} to the existing notification history" do
        user = navigation_user(role)
        allow(helper).to receive(:current_user).and_return(user)

        expect(helper.whatsapp_navigation_path).to eq(helper.public_send(route_helper))
      end
    end
  end

  it "resolves every visible sidebar item without a placeholder link" do
    %i[admin staff teacher student].each do |role|
      user = navigation_user(role)
      allow(helper).to receive(:current_user).and_return(user)

      helper.navigation_items_for(user).each do |key, item|
        expect(helper.navigation_path(key, item)).to be_present
        expect(helper.navigation_path(key, item)).not_to eq("#")
      end
    end
  end

  it "limits the admin sidebar to the temporary navigation allowlist" do
    admin = navigation_user(:admin)

    expect(helper.navigation_items_for(admin).keys).to eq(
      %i[dashboard students teachers schedule profits_analytics fee_plans financial_reports]
    )
  end

  def navigation_user(role)
    instance_double(User, role: role.to_s, student?: role == :student, teacher?: role == :teacher)
  end
end
