require "rails_helper"

RSpec.describe Notifications::RecipientResolver do
  def resolve(user, channel: "whatsapp")
    described_class.new(user:, channel:).call
  end

  def student_with_primary_guardian(student_attrs: {}, guardian_attrs: {})
    student = create(:student_profile, **student_attrs)
    guardian = create(:guardian, **guardian_attrs)
    create(:student_guardianship, student_profile: student, guardian:, primary_contact: true, status: "active")
    student
  end

  it "uses the student's own whatsapp_number when present" do
    student = student_with_primary_guardian(
      student_attrs: { whatsapp_number: "+201001234567" },
      guardian_attrs: { whatsapp_number: "+201009999999" }
    )

    recipient = resolve(student.user)

    expect(recipient.valid?).to be(true)
    expect(recipient.provider_address).to eq("201001234567")
    expect(recipient.guardian).to be_nil
  end

  it "falls back to the primary guardian's whatsapp_number when the student has none" do
    student = student_with_primary_guardian(guardian_attrs: { whatsapp_number: "+201009999999" })

    recipient = resolve(student.user)

    expect(recipient.valid?).to be(true)
    expect(recipient.provider_address).to eq("201009999999")
    expect(recipient.guardian).to eq(student.student_guardianships.first.guardian)
  end

  it "falls back to the primary guardian's phone_number when neither has whatsapp" do
    student = student_with_primary_guardian(guardian_attrs: { phone_number: "+201008888888" })

    recipient = resolve(student.user)

    expect(recipient.valid?).to be(true)
    expect(recipient.provider_address).to eq("201008888888")
  end

  it "applies the fallback for adult students too, not only minors" do
    student = student_with_primary_guardian(
      student_attrs: { student_type: "adult" },
      guardian_attrs: { whatsapp_number: "+201007777777" }
    )

    recipient = resolve(student.user)

    expect(recipient.valid?).to be(true)
    expect(recipient.provider_address).to eq("201007777777")
  end

  it "skips cleanly when neither the student nor the guardian has a usable number" do
    student = student_with_primary_guardian

    recipient = resolve(student.user)

    expect(recipient.valid?).to be(false)
    expect(recipient.error).to eq(:invalid_phone)
  end

  it "does not fall back to a non-primary guardian" do
    student = create(:student_profile)
    guardian = create(:guardian, whatsapp_number: "+201006666666")
    create(:student_guardianship, student_profile: student, guardian:, primary_contact: false, status: "active")

    recipient = resolve(student.user)

    expect(recipient.valid?).to be(false)
  end

  it "does not fall back to an inactive guardianship" do
    student = create(:student_profile)
    guardian = create(:guardian, whatsapp_number: "+201005555555")
    create(:student_guardianship, student_profile: student, guardian:, primary_contact: true, status: "inactive")

    recipient = resolve(student.user)

    expect(recipient.valid?).to be(false)
  end

  it "does not apply the guardian fallback to teachers" do
    teacher = create(:teacher_profile, whatsapp_number: nil, phone_number: nil)

    recipient = resolve(teacher.user)

    expect(recipient.valid?).to be(false)
    expect(recipient.guardian).to be_nil
  end

  it "does not apply the guardian fallback to the email channel" do
    student = student_with_primary_guardian(guardian_attrs: { whatsapp_number: "+201004444444" })
    student.user.update!(email: "student@example.test")

    recipient = resolve(student.user, channel: "email")

    expect(recipient.valid?).to be(true)
    expect(recipient.guardian).to be_nil
    expect(recipient.address).to eq("student@example.test")
  end
end
