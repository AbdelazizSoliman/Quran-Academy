require "rails_helper"

RSpec.describe StudentLearningProfileSection do
  it "registers all twelve stable dimensions in their required order and importance" do
    definitions = StudentLearningProfileSectionRegistry::DEFINITIONS
    expect(definitions.size).to eq(12)
    expect(definitions.values.pluck(:position)).to eq((1..12).to_a)
    expect(definitions.values_at("basic_information", "psychological_emotional_state").pluck(:importance))
      .to eq(%w[must must])
    expect(definitions.fetch("language_cultural_background")[:importance]).to eq("should")
    expect(definitions.fetch("achievements_aspirations")[:importance]).to eq("could")
  end

  it "applies registry defaults and supports sparse sections" do
    section = create(:student_learning_profile_section, section_key: "family_social_context")
    expect(section.attributes).to include("completion_state" => "not_started", "review_state" => "unreviewed")
    expect(section.position).to eq(10)
    expect(section.importance).to eq("should")
    expect(described_class.column_names).not_to include("position", "importance")
    expect(section.student_learning_profile.sections.count).to eq(1)
  end

  it "rejects unknown and duplicate section keys" do
    profile = create(:student_learning_profile)
    create(:student_learning_profile_section, student_learning_profile: profile)
    duplicate = build(:student_learning_profile_section, student_learning_profile: profile)
    unknown = build(:student_learning_profile_section, section_key: "diagnosis")
    expect(duplicate).not_to be_valid
    expect(unknown).not_to be_valid
  end

  it "requires reviewer metadata only for reviewed sections" do
    section = build(:student_learning_profile_section, review_state: "reviewed")
    expect(section).not_to be_valid
    reviewer = create(:user, :admin)
    section.reviewed_by = reviewer
    section.reviewed_at = Time.current
    expect(section).to be_valid
  end
end
