require "rails_helper"

RSpec.describe "Admin website analytics" do
  it "requires an administrator" do
    get admin_website_analytics_path
    expect(response).to redirect_to(new_user_session_path)

    sign_in create(:user, :staff)
    get admin_website_analytics_path
    expect(response).to have_http_status(:forbidden)
  end

  it "renders bounded summary data for an administrator" do
    sign_in create(:user, :admin)
    create(:public_analytics_event, event_type: "page_view", occurred_at: 1.day.ago)
    create(:public_analytics_event, event_type: "trial_cta_click", occurred_at: 1.day.ago)

    get admin_website_analytics_path, params: { days: 7 }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("admin.website.analytics.title"))
    expect(response.body).to include(I18n.t("admin.website.analytics.range", days: 7))
  end
end
