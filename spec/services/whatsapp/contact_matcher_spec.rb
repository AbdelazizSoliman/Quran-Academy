require "rails_helper"

RSpec.describe Whatsapp::ContactMatcher do
  subject(:match) { described_class.call(phone) }

  let(:phone) { "+201001234567" }

  it "matches a normalized student number" do
    student = create(:student_profile, whatsapp_number: "+20 100-123-4567")

    expect(match).to eq(student)
  end

  it "matches a normalized guardian number" do
    guardian = create(:guardian, whatsapp_number: phone, phone_number: "+201009999999",
                                 preferred_contact_method: "whatsapp")

    expect(match).to eq(guardian)
  end

  it "matches a normalized teacher number" do
    teacher = create(:teacher_profile, whatsapp_number: phone)

    expect(match).to eq(teacher)
  end

  it "matches a normalized staff number" do
    staff = create(:staff_profile, whatsapp_number: phone, phone_number: phone)

    expect(match).to eq(staff)
  end

  it "returns nil instead of choosing when records share a number" do
    create(:student_profile, whatsapp_number: phone)
    create(:teacher_profile, whatsapp_number: phone)

    expect(match).to be_nil
  end
end
