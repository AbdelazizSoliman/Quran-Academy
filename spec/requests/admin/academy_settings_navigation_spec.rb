require "rails_helper"

RSpec.describe "Academy settings navigation" do
  it "keeps settings accessible while hiding it from the admin sidebar" do
    admin = create(:user, :admin)
    sign_in admin
    get admin_settings_path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(%(href="#{admin_settings_path}"))

    sign_out admin
    sign_in create(:user, :staff)
    get root_path
    expect(response.body).not_to include(admin_settings_path)
  end
end
