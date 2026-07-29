require "rails_helper"

RSpec.describe TeacherProfile do
  before { AcademySetting.current.update!(teaching_languages: %w[ar en]) }

  it "belongs to one teacher user and receives a database-generated public ID" do
    profile = create(:teacher_profile)

    expect(profile.user.teacher_profile).to eq(profile)
    expect(profile.public_id).to match(/\ATCH-[A-Z0-9]{10}\z/)
    expect { create(:teacher_profile, user: profile.user) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rejects a non-teacher owner" do
    profile = build(:teacher_profile, user: build(:user, :staff))

    expect(profile).not_to be_valid
    expect(profile.errors[:user]).to be_present
  end

  it "validates controlled catalogs and academy teaching languages" do
    profile = build(:teacher_profile, gender: "other", employment_status: "busy",
                                      teaching_languages: %w[xx], student_age_groups: %w[unknown],
                                      teaching_specializations: %w[unknown])

    expect(profile).not_to be_valid
    expect(profile.errors.attribute_names).to include(
      :gender, :employment_status, :teaching_languages, :student_age_groups, :teaching_specializations
    )
  end

  it "normalizes arrays and conservative contact values" do
    profile = create(:teacher_profile, teaching_languages: ["", "ar", "ar"],
                                       phone_number: " +20123 ")

    expect(profile.teaching_languages).to eq(%w[ar])
    expect(profile.phone_number).to eq("+20123")
  end

  it "validates experience, date ordering, departed dates, and compensation" do
    profile = build(:teacher_profile, years_of_teaching_experience: 2,
                                      quran_teaching_experience_years: 3,
                                      joined_on: Date.current, left_on: 1.day.ago,
                                      employment_status: "departed", default_lesson_rate: -1)

    expect(profile).not_to be_valid
    expect(profile.errors.attribute_names).to include(
      :quran_teaching_experience_years, :left_on, :default_lesson_rate
    )
  end

  it "requires meaningful capability fields only for complete or verified profiles" do
    draft = build(:teacher_profile, profile_status: "draft", teaching_languages: [],
                                    student_age_groups: [], teaching_specializations: [])
    complete = build(:teacher_profile, profile_status: "complete", teaching_languages: [],
                                       student_age_groups: [], teaching_specializations: [])

    expect(draft).to be_valid
    expect(complete).not_to be_valid
  end

  it "calculates completion without storing a percentage" do
    profile = build(:teacher_profile)

    expect(profile.completion_percentage).to eq(100)
    expect(profile).to be_complete
    profile.bio = nil
    expect(profile.missing_required_fields).to include(:bio)
    expect(profile.completion_percentage).to be < 100
  end

  it "uses academy compensation and language defaults for new profiles" do
    AcademySetting.current.update!(
      teaching_languages: %w[en], default_teacher_rate: 77,
      payroll_currency: "USD", default_teacher_compensation_type: "hourly"
    )
    profile = described_class.new(user: create(:user, :teacher), default_lesson_rate: nil,
                                  compensation_currency: nil, compensation_unit: nil)
    profile.valid?

    expect(profile.attributes.values_at("teaching_languages", "default_lesson_rate",
                                        "compensation_currency", "compensation_unit"))
      .to eq([%w[en], BigDecimal("77"), "USD", "hourly"])
  end

  it "prevents changing a profiled teacher to another role" do
    profile = create(:teacher_profile)

    expect(profile.user.update(role: :staff)).to be(false)
    expect(profile.user.errors[:role]).to be_present
  end
end
