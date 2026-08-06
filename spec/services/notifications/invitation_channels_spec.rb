require "rails_helper"

RSpec.describe Notifications::InvitationChannels do
  it "sends email only when the teacher's notification_method is email" do
    teacher = create(:teacher_profile, notification_method: "email")
    expect(described_class.call(user: teacher.user)).to eq(%w[email])
  end

  it "sends whatsapp only when the teacher's notification_method is whatsapp" do
    teacher = create(:teacher_profile, notification_method: "whatsapp")
    expect(described_class.call(user: teacher.user)).to eq(%w[whatsapp])
  end

  it "sends both when the teacher's notification_method is both" do
    teacher = create(:teacher_profile, notification_method: "both")
    expect(described_class.call(user: teacher.user)).to eq(%w[email whatsapp])
  end

  it "sends email only when the student's account_delivery_method is email" do
    student = create(:student_profile, account_delivery_method: "email")
    expect(described_class.call(user: student.user)).to eq(%w[email])
  end

  it "sends whatsapp only when the student's account_delivery_method is whatsapp" do
    student = create(:student_profile, account_delivery_method: "whatsapp")
    expect(described_class.call(user: student.user)).to eq(%w[whatsapp])
  end

  it "sends both when the student's account_delivery_method is both" do
    student = create(:student_profile, account_delivery_method: "both")
    expect(described_class.call(user: student.user)).to eq(%w[email whatsapp])
  end

  it "falls back to email only when the user has no teacher or student profile" do
    user = create(:user, :pending)
    expect(described_class.call(user:)).to eq(%w[email])
  end
end
