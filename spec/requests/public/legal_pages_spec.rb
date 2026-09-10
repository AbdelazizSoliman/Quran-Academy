require "rails_helper"

RSpec.describe "Public legal pages" do
  let(:academy_setting) { create(:academy_setting) }

  before { create(:public_website_setting, academy_setting:) }

  it "returns controlled 404s for unpublished pages and hides their footer links" do
    create(:public_legal_page, page_type: "privacy")
    get public_privacy_path(locale: :en)
    expect(response).to have_http_status(:not_found)
    get localized_public_home_path(locale: :en)
    expect(response.body).not_to include(public_privacy_path(locale: :en))
  end

  it "renders published legal content in each locale without fallback" do
    create(:public_legal_page, :published, page_type: "privacy", title_ar: "خصوصية", title_en: "Privacy",
                                           body_ar: "عربي فقط", body_en: "English only")
    get public_privacy_path(locale: :en)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Privacy", "English only", 'dir="ltr"')
    expect(response.body).not_to include("خصوصية", "عربي فقط")
    get public_privacy_path(locale: :ar)
    expect(response.body).to include("خصوصية", "عربي فقط", 'dir="rtl"')
    expect(response.body).not_to include("English only")
  end

  it "keeps the legal footer links conditional per page" do
    create(:public_legal_page, :published, page_type: "privacy")
    create(:public_legal_page, :published, page_type: "terms")
    get localized_public_home_path(locale: :en)
    expect(response.body).to include(public_privacy_path(locale: :en), public_terms_path(locale: :en))
    expect(response.body).not_to include(public_refund_policy_path(locale: :en))
  end

  it "keeps disabled websites unavailable" do
    academy_setting.public_website_setting.update!(enabled: false)
    create(:public_legal_page, :published, page_type: "privacy")
    get public_privacy_path(locale: :en)
    expect(response).to have_http_status(:service_unavailable)
  end
end
