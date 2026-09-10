require "rails_helper"

RSpec.describe "Admin website legal pages" do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  # rubocop:disable RSpec/ExampleLength
  it "lists policy types and creates or updates one record per type" do
    get admin_website_legal_pages_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("admin.website.legal_pages.title"))
    patch admin_website_legal_page_path("privacy"), params: {
      public_legal_page: {
        title_ar: "خصوصية", title_en: "Privacy", body_ar: "عربي", body_en: "English", published: "1",
        effective_date: "2026-09-10"
      }
    }
    page = PublicLegalPage.find_by!(page_type: "privacy")
    expect(response).to redirect_to(admin_website_legal_pages_path)
    expect(page).to have_attributes(published: true, updated_by: admin, created_by: admin)
    patch admin_website_legal_page_path("privacy"), params: {
      public_legal_page: { published: "0", created_by_id: -1, updated_by_id: -1 }
    }
    expect(page.reload.published).to be(false)
    expect(page.updated_by).to eq(admin)
  end
  # rubocop:enable RSpec/ExampleLength

  it "rejects incomplete publication and non-admin access" do
    patch admin_website_legal_page_path("terms"), params: {
      public_legal_page: { title_ar: "شروط", title_en: "", body_ar: "عربي", body_en: "English", published: "1" }
    }
    expect(response).to have_http_status(:unprocessable_content)
    sign_out admin
    sign_in create(:user, :staff)
    get admin_website_legal_pages_path
    expect(response).to have_http_status(:forbidden)
  end
end
