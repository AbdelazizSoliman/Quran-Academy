require "rails_helper"

RSpec.describe PublicLegalPage do
  it "requires complete bilingual content before publication" do
    page = build(:public_legal_page, title_en: nil, body_ar: nil)
    expect(page).to be_valid
    page.published = true
    expect(page).not_to be_valid
    expect(page.errors).to include(:title_en, :body_ar)
  end

  it "allows only the supported page types and one record per type" do
    expect(build(:public_legal_page, page_type: "cookies")).not_to be_valid
    create(:public_legal_page, page_type: "privacy")
    expect(build(:public_legal_page, page_type: "privacy")).not_to be_valid
  end
end
