require "rails_helper"

RSpec.describe StudentLearningProfileItem do
  it "stores sparse typed JSON values" do
    section = create(:student_learning_profile_section, section_key: "cognitive_traits_learning_preferences")
    item = create(:student_learning_profile_item, section:, field_key: "preferred_activities",
                                                  value: %w[repetition demonstration], value_type: "list")
    expect(item.reload.value).to eq(%w[repetition demonstration])
  end

  it "validates field keys, catalogs, value type, and uniqueness within a section" do
    item = create(:student_learning_profile_item)
    duplicate = build(:student_learning_profile_item, section: item.section, field_key: item.field_key)
    invalid = build(:student_learning_profile_item, field_key: "Medical Diagnosis", value_type: "boolean",
                                                    value: "yes", sensitivity: "secret", visibility: "public")
    expect(duplicate).not_to be_valid
    expect(invalid).not_to be_valid
    expect(invalid.errors).to include(:field_key, :value, :sensitivity, :visibility)
  end

  it "defaults sensitivity and visibility conservatively" do
    item = create(:student_learning_profile_item, sensitivity: nil, visibility: nil)
    expect(item.sensitivity).to eq("standard")
    expect(item.visibility).to eq("internal")
  end

  it "rejects canonical and otherwise unregistered fields" do
    %w[student_name email phone_number guardian_phone assigned_teacher attendance_percentage assessment_score
       lesson_history current_quran_level].each do |field_key|
      expect(build(:student_learning_profile_item, field_key:)).not_to be_valid
    end
  end

  it "uses field definitions for type and minimum sensitivity" do
    section = create(:student_learning_profile_section, section_key: "challenges_support_needs")
    item = build(:student_learning_profile_item, section:, field_key: "support_context", sensitivity: nil)
    downgraded = build(:student_learning_profile_item, section:, field_key: "support_context",
                                                       sensitivity: "standard")
    expect(item).to be_valid
    expect(item.sensitivity).to eq("sensitive")
    expect(downgraded).not_to be_valid
  end

  it "validates ISO dates and serialized value size" do
    section = create(:student_learning_profile_section, section_key: "challenges_support_needs")
    invalid_date = build(:student_learning_profile_item, section:, field_key: "support_review_date",
                                                         value: "16/09/2026")
    too_large = build(:student_learning_profile_item, value: "x" * 10_001)
    expect(invalid_date).not_to be_valid
    expect(too_large).not_to be_valid
  end
end
