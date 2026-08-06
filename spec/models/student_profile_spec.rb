require "rails_helper"

RSpec.describe StudentProfile do
  it "belongs to one student user and generates an immutable public ID" do
    profile = create(:student_profile)
    expect(profile.public_id).to match(/\ASTD-[A-Z0-9]{10}\z/)
    expect(profile.user.student_profile).to eq(profile)
    expect(build(:student_profile, user: build(:user, :teacher))).not_to be_valid
    expect { create(:student_profile, user: profile.user) }.to raise_error(ActiveRecord::RecordInvalid)

    original = profile.public_id
    expect { profile.update!(public_id: "STD-AAAAAAAAAA") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect(profile.reload.public_id).to eq(original)
  end

  it "validates catalogs, learning language, juz range, and lifecycle dates" do
    profile = build(:student_profile, student_type: "senior", preferred_learning_language: "xx",
                                      memorized_juz_count: 31, joined_on: Date.current, left_on: Date.yesterday)
    expect(profile).not_to be_valid
    expect(profile.errors).to include(:student_type, :preferred_learning_language, :memorized_juz_count, :left_on)
  end

  it "calculates age without rewriting student type and reports mismatch" do
    profile = build(:student_profile, student_type: "adult", date_of_birth: 10.years.ago.to_date)
    expect(profile.age).to be_between(9, 10)
    expect(profile).to be_age_type_mismatch
    expect(profile.student_type).to eq("adult")
  end

  it "permits adult verification without guardians when required fields exist" do
    profile = build(:student_profile, :complete, profile_status: "verified")
    expect(profile).to be_valid
  end

  it "requires complete guardian readiness before minor verification" do
    profile = create(:student_profile, :minor)
    profile.profile_status = "verified"
    expect(profile).not_to be_valid

    guardian = create(:guardian)
    create(:student_guardianship, student_profile: profile, guardian:, primary_contact: true,
                                  emergency_contact: true, legal_guardian: true)
    expect(profile.reload.tap { |record| record.profile_status = "verified" }).to be_valid
  end

  it "calculates completeness and missing requirements dynamically" do
    profile = build(:student_profile, display_name: nil, learning_goals: nil)
    expect(profile.missing_required_fields).to include(:display_name, :learning_goals)
    expect(profile.completion_percentage).to be_between(0, 99)
  end

  it "protects the user's role while a student profile exists" do
    user = create(:student_profile).user
    expect(user.update(role: :staff)).to be(false)
    expect(user.errors[:role]).to be_present
  end
end
