require "rails_helper"

RSpec.describe "Admin navigation" do
  it "shows the real user-management link only to administrators" do
    admin = create(:user, :admin)
    sign_in admin
    get root_path
    expect(response.body).to include(admin_users_path)

    sign_out admin
    sign_in create(:user, :staff)
    get root_path
    expect(response.body).not_to include(admin_users_path)
  end
end
