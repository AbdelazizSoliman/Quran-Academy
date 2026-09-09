require "rails_helper"

RSpec.describe PublicInquiry do
  it "normalizes names, email, and existing project phone formats" do
    inquiry = create(:public_inquiry, name: "  Amina Hassan  ", email: " AMINA@EXAMPLE.TEST ",
                                      phone: "010 1234 5678", whatsapp_number: "+20 (111) 222-3344")

    expect(inquiry).to have_attributes(name: "Amina Hassan", email: "amina@example.test",
                                       phone: "+201012345678", whatsapp_number: "+201112223344")
  end

  it "requires a reachable contact method and contact message" do
    inquiry = build(:public_inquiry, :contact, phone: nil, email: nil, message: nil)

    expect(inquiry).not_to be_valid
    expect(inquiry.errors[:base]).to be_present
    expect(inquiry.errors[:message]).to be_present
  end

  it "rejects invalid phone numbers" do
    inquiry = build(:public_inquiry, phone: "not-a-phone")

    expect(inquiry).not_to be_valid
    expect(inquiry.errors[:phone]).to be_present
  end
end
