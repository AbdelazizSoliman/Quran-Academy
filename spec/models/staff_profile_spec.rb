require "rails_helper"

RSpec.describe StaffProfile do
  it "stores normalized contact details for staff and administrators" do
    profile = create(:staff_profile)

    expect(profile.public_id).to match(/\ASTF-[A-Z0-9]{10}\z/)
    expect(profile.whatsapp_number).to eq(profile.phone_number)
  end

  it "rejects teaching and student roles" do
    profile = build(:staff_profile, user: build(:user, :teacher))

    expect(profile).not_to be_valid
    expect(profile.errors[:user]).to be_present
  end
end
