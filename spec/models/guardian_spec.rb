require "rails_helper"

RSpec.describe Guardian do
  it "generates an immutable public ID and preserves international phones" do
    guardian = create(:guardian, email: nil, phone_number: " +44 20 1234 ", preferred_contact_method: "phone")
    expect(guardian.public_id).to match(/\AGRD-[A-Z0-9]{10}\z/)
    expect(guardian.phone_number).to eq("+44 20 1234")
  end

  it "requires a usable active contact and matching preferred method" do
    guardian = build(:guardian, email: nil, phone_number: nil, whatsapp_number: nil)
    expect(guardian).not_to be_valid
    guardian.email = "guardian@example.test"
    guardian.preferred_contact_method = "whatsapp"
    expect(guardian).not_to be_valid
  end

  it "retains linked students when archived" do
    link = create(:student_guardianship)
    link.guardian.update!(status: "archived")
    expect(link.reload).to be_present
  end
end
