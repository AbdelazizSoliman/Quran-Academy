require "rails_helper"

RSpec.describe "Admin public website settings" do
  let(:academy_setting) { create(:academy_setting) }
  let(:admin) { create(:user, :admin) }
  let(:valid_attributes) do
    PublicWebsiteSetting.defaults.merge(
      enabled: true, hero_title_en: "A clear path to learning", public_email_enabled: true
    )
  end

  before do
    academy_setting
    sign_in admin
  end

  it "lets an admin open the editor without persisting a record" do
    expect { get edit_admin_public_website_path }.not_to change(PublicWebsiteSetting, :count)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("admin.public_website.title"))
  end

  it "creates and updates the Phase 1 settings" do
    expect do
      patch admin_public_website_path, params: {
        public_website_setting: valid_attributes
      }
    end.to change(PublicWebsiteSetting, :count).by(1)

    expect(response).to redirect_to(edit_admin_public_website_path)
    expect(academy_setting.reload.public_website_setting).to have_attributes(
      enabled: true,
      hero_title_en: "A clear path to learning",
      public_email_enabled: true
    )
  end

  it "rejects non-admin users" do
    sign_out admin
    sign_in create(:user, :staff)

    get edit_admin_public_website_path

    expect(response).to have_http_status(:forbidden)
  end
end
