require "rails_helper"

RSpec.describe PublicWebsiteSetting do
  subject(:setting) { build(:public_website_setting) }

  it "is valid with the Phase 1 fields" do
    expect(setting).to be_valid
  end

  it "enforces one public website setting per academy setting" do
    existing = create(:public_website_setting)
    duplicate = build(:public_website_setting, academy_setting: existing.academy_setting)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:academy_setting_id]).to be_present
  end

  it "rejects unsafe primary action URLs" do
    setting.primary_cta_url = "javascript:alert(1)"

    expect(setting).not_to be_valid
  end
end
