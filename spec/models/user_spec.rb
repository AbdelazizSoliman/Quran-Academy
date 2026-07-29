require "rails_helper"

RSpec.describe User do
  subject(:user) { build(:user) }

  it "is valid with the factory defaults" do
    expect(user).to be_valid
  end

  it "validates role values" do
    user.role = "unknown"

    expect(user).not_to be_valid
    expect(user.errors[:role]).to be_present
  end

  it "validates status values" do
    user.status = "unknown"

    expect(user).not_to be_valid
    expect(user.errors[:status]).to be_present
  end

  it "validates supported locales" do
    user.preferred_locale = "fr"

    expect(user).not_to be_valid
    expect(user.errors[:preferred_locale]).to be_present
  end

  it "validates ActiveSupport time zones" do
    user.time_zone = "Not/A-Time-Zone"

    expect(user).not_to be_valid
    expect(user.errors[:time_zone]).to be_present
  end

  it "returns a full name and falls back to the email local part" do
    expect(user.full_name).to eq("#{user.first_name} #{user.last_name}")

    user.first_name = user.last_name = nil
    expect(user.full_name).to eq(user.email.split("@").first)
  end

  it "defaults students to English" do
    student = described_class.new(role: :student)

    student.valid?

    expect(student.preferred_locale).to eq("en")
  end

  it "defaults non-students to Arabic" do
    staff = described_class.new(role: :staff)

    staff.valid?

    expect(staff.preferred_locale).to eq("ar")
  end

  it "preserves an explicitly supplied locale" do
    teacher = described_class.new(role: :teacher, preferred_locale: "en")

    teacher.valid?

    expect(teacher.preferred_locale).to eq("en")
  end

  it "defaults blank time zones to Cairo" do
    user.time_zone = nil

    user.valid?

    expect(user.time_zone).to eq("Cairo")
  end

  it "allows only active accounts to authenticate" do
    expect(build(:user, :active).active_for_authentication?).to be(true)
    expect(build(:user, :pending).active_for_authentication?).to be(false)
    expect(build(:user, :suspended).active_for_authentication?).to be(false)
    expect(build(:user, :disabled).active_for_authentication?).to be(false)
  end

  it "returns status-specific inactive messages" do
    expect(build(:user, :pending).inactive_message).to eq(:pending_account)
    expect(build(:user, :suspended).inactive_message).to eq(:suspended_account)
    expect(build(:user, :disabled).inactive_message).to eq(:disabled_account)
  end
end
