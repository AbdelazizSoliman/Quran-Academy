require "rails_helper"

RSpec.describe "Admin website leads" do
  let(:admin) { create(:user, :admin) }
  let!(:trial) { create(:public_inquiry, name: "Trial Lead") }
  let(:contact) { create(:public_inquiry, :contact, name: "Contact Lead", status: "contacted") }

  it "blocks anonymous and non-admin users" do
    get admin_website_leads_path
    expect(response).to redirect_to(new_user_session_path)

    sign_in create(:user, :student)
    get admin_website_leads_path
    expect(response).to have_http_status(:forbidden)
  end

  it "lists and filters leads for admins" do
    contact
    sign_in admin

    get admin_website_leads_path(type: "trial", status: "new")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Trial Lead", admin_website_lead_path(trial))
    expect(response.body).not_to include("Contact Lead")
  end

  it "shows submitted details without rendering user HTML" do
    trial.update!(message: "<script>alert(1)</script>")
    sign_in admin

    get admin_website_lead_path(trial)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("<script>alert(1)</script>")
    expect(response.body).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
  end

  it "updates status and internal notes with handling attribution" do
    sign_in admin

    patch admin_website_lead_path(trial), params: {
      public_inquiry: { status: "qualified", internal_notes: "Good fit" }
    }

    expect(response).to redirect_to(admin_website_lead_path(trial))
    expect(trial.reload).to have_attributes(status: "qualified", internal_notes: "Good fit", handled_by: admin)
    expect(trial.handled_at).to be_present
  end
end
