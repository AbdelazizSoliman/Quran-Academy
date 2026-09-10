require "rails_helper"

RSpec.describe "Public sitemap and robots" do
  let(:academy_setting) { create(:academy_setting) }

  before { create(:public_website_setting, academy_setting:) }

  it "includes enabled public pages and published content only" do
    create(:public_faq, :published)
    create(:public_legal_page, :published, page_type: "privacy")
    create(:public_legal_page, page_type: "terms")
    get sitemap_path
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/xml")
    expect(response.body).to include("https://www.example.com/en", "https://www.example.com/en/faq", "https://www.example.com/en/privacy")
    expect(response.body).not_to include("/terms")
    expect(response.body).not_to include("/admin", "/dashboard", "/student")
  end

  it "excludes all public URLs when the website is disabled" do
    academy_setting.public_website_setting.update!(enabled: false)
    get sitemap_path
    expect(response.body).not_to include("/en", "/fees", "/faq")
    get robots_path
    expect(response.body).to include("Disallow: /")
    expect(response.body).not_to include("Sitemap:")
  end

  it "allows public crawling while disallowing private paths" do
    get robots_path
    expect(response.body).to include("Allow: /", "Disallow: /admin/", "Disallow: /dashboard", "Disallow: /account/",
                                     "Sitemap: https://www.example.com/sitemap.xml")
  end
end
