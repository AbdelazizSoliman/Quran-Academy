require "rails_helper"

RSpec.describe "Admin financial dashboard" do
  it "renders estimated financial metrics for administrators" do
    sign_in create(:user, :admin)

    get admin_financial_dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("financial_dashboard.title", locale: :ar))
    expect(response.body).to include(I18n.t("financial_dashboard.estimate_notice_title", locale: :ar))
  end

  it "does not allow non-admin users" do
    sign_in create(:user, :teacher)

    get admin_financial_dashboard_path

    expect(response).to have_http_status(:forbidden)
  end
end
