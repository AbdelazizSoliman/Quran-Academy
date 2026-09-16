require "rails_helper"

# These examples exercise several authorization branches intentionally at the service boundary.
# rubocop:disable RSpec/ExampleLength
RSpec.describe "Student learning profile services" do
  let(:admin) { create(:user, :admin) }
  let(:teacher_profile) { create(:teacher_profile, :active, :verified) }
  let(:teacher) { teacher_profile.user }
  let(:student) { create(:student_profile, assigned_teacher_profile: teacher_profile) }

  it "creates a profile lazily and audits its origin" do
    expect do
      profile = StudentLearningProfiles::EnsureExists.new(actor: teacher, student_profile: student).call
      expect(profile.events.last.attributes).to include("action" => "profile_created", "source" => "teacher_entry")
    end.to change(StudentLearningProfile, :count).by(1)
       .and change(StudentLearningProfileEvent, :count).by(1)
  end

  it "creates sparse sections and audits standard item values" do
    profile = StudentLearningProfiles::EnsureExists.new(actor: teacher, student_profile: student).call
    section = StudentLearningProfiles::UpsertSection.new(actor: teacher, profile:,
                                                         section_key: "personality_motivation").call
    item = StudentLearningProfiles::UpsertItem.new(actor: teacher, section:, field_key: "feedback_preference",
                                                   attributes: { value: "Responds to attainable goals" }).call
    expect(item).to be_persisted
    expect(item.events.last.new_value.to_s).to include("Responds to attainable goals")
  end

  it "masks sensitive values in audit history" do
    section = profile_section
    attributes = { value: "Private context", sensitivity: "sensitive" }
    item = StudentLearningProfiles::UpsertItem.new(actor: teacher, section:, field_key: "support_context",
                                                   attributes:).call
    event = item.events.last
    expect(event.metadata).to eq("sensitive_value_changed" => true)
    expect(event.attributes.values.to_s).not_to include("Private context")
  end

  it "records previous and new values for standard item updates" do
    section = admin_section("cognitive_traits_learning_preferences")
    item = build_item(section, "preferred_pacing", value: "short")
    updated = build_item(section, "preferred_pacing", value: "moderate")
    expect(updated).to eq(item)
    expect(updated.events.last.previous_value["value"]).to eq("short")
    expect(updated.events.last.new_value["value"]).to eq("moderate")
  end

  it "blocks teachers from highly sensitive entries and sharing sensitive entries" do
    section = profile_section
    shared_sensitive = build_item(section, "support_context", visibility: "guardian_safe")
    expect(shared_sensitive.errors.details[:base]).to include(error: :forbidden)
  end

  it "prevents teachers from editing, downgrading, or exposing protected items" do
    section = admin_section("psychological_emotional_state")
    highly_sensitive = admin_item(section, "emotional_response")
    denied_edit = teacher_item(section, "emotional_response", value: "Changed")
    denied_downgrade = teacher_item(section, "emotional_response", sensitivity: "standard")
    expect(highly_sensitive).to be_persisted
    expect(denied_edit.errors.details[:base]).to include(error: :forbidden)
    expect(denied_downgrade.errors.details[:base]).to include(error: :forbidden)

    sensitive_section = admin_section("challenges_support_needs")
    admin_item(sensitive_section, "support_context")
    downgrade = teacher_item(sensitive_section, "support_context", sensitivity: "standard")
    exposure = teacher_item(sensitive_section, "support_context", visibility: "student_safe")
    expect(downgrade.errors.details[:base]).to include(error: :forbidden)
    expect(exposure.errors.details[:base]).to include(error: :forbidden)
  end

  it "allows administrators to manage every student and highly sensitive items" do
    unrelated = create(:student_profile)
    profile = StudentLearningProfiles::EnsureExists.new(actor: admin, student_profile: unrelated).call
    section = StudentLearningProfiles::UpsertSection.new(actor: admin, profile:,
                                                         section_key: "psychological_emotional_state").call
    item = StudentLearningProfiles::UpsertItem.new(actor: admin, section:, field_key: "emotional_response",
                                                   attributes: { value: "Observed response",
                                                                 sensitivity: "highly_sensitive" }).call
    expect(item).to be_persisted
  end

  it "denies unrelated teachers at every mutation service boundary" do
    unrelated = create(:teacher_profile, :active, :verified).user
    profile = StudentLearningProfiles::EnsureExists.new(actor: admin, student_profile: student).call
    section = StudentLearningProfiles::UpsertSection.new(actor: admin, profile:,
                                                         section_key: "personality_motivation").call
    ensure_result = StudentLearningProfiles::EnsureExists.new(actor: unrelated, student_profile: student).call
    section_result = StudentLearningProfiles::UpsertSection.new(actor: unrelated, profile:,
                                                                section_key: "interests_personal_culture").call
    item_result = StudentLearningProfiles::UpsertItem.new(actor: unrelated, section:,
                                                          field_key: "feedback_preference",
                                                          attributes: { value: "Private" }).call
    expect(ensure_result.errors.details[:base]).to include(error: :forbidden)
    expect(section_result.errors.details[:base]).to include(error: :forbidden)
    expect(item_result.errors.details[:base]).to include(error: :forbidden)
  end

  it "allows only admins to transition review state and owns reviewer metadata" do
    section = profile_section
    teacher_attempt = StudentLearningProfiles::UpsertSection.new(
      actor: teacher, profile: section.student_learning_profile, section_key: section.section_key,
      attributes: { review_state: "reviewed", reviewed_by_id: create(:user, :admin).id,
                    reviewed_at: 1.year.ago }
    ).call
    expect(teacher_attempt.errors.details[:base]).to include(error: :forbidden)

    reviewed = StudentLearningProfiles::UpsertSection.new(
      actor: admin, profile: section.student_learning_profile, section_key: section.section_key,
      attributes: { review_state: "reviewed", reviewed_by_id: teacher.id, reviewed_at: 1.year.ago }
    ).call
    expect(reviewed.reviewed_by).to eq(admin)
    expect(reviewed.reviewed_at).to be_within(2.seconds).of(Time.current)
  end

  it "clears review metadata when an admin leaves reviewed state" do
    section = admin_section("basic_information")
    reviewed = StudentLearningProfiles::UpsertSection.new(actor: admin, profile: section.student_learning_profile,
                                                          section_key: section.section_key,
                                                          attributes: { review_state: "reviewed" }).call
    unreviewed = StudentLearningProfiles::UpsertSection.new(actor: admin,
                                                            profile: reviewed.student_learning_profile,
                                                            section_key: reviewed.section_key,
                                                            attributes: { review_state: "unreviewed" }).call
    expect(unreviewed.reviewed_by).to be_nil
    expect(unreviewed.reviewed_at).to be_nil
  end

  it "ignores caller-supplied item sources and emits no events for no-op updates" do
    section = admin_section("basic_information")
    item = StudentLearningProfiles::UpsertItem.new(actor: teacher, section:, field_key: "instructional_summary",
                                                   attributes: { value: "Summary", source: "admin_entry" }).call
    expect(item.source).to eq("teacher_entry")
    expect do
      teacher_item(section, "instructional_summary", value: "Summary")
    end.not_to change(StudentLearningProfileEvent, :count)
    expect do
      StudentLearningProfiles::UpsertSection.new(actor: teacher, profile: section.student_learning_profile,
                                                 section_key: section.section_key).call
    end.not_to change(StudentLearningProfileEvent, :count)
  end

  private

  def profile_section
    profile = StudentLearningProfiles::EnsureExists.new(actor: teacher, student_profile: student).call
    StudentLearningProfiles::UpsertSection.new(actor: teacher, profile:,
                                               section_key: "challenges_support_needs").call
  end

  def build_item(section, key, attributes)
    StudentLearningProfiles::UpsertItem.new(actor: teacher, section:, field_key: key,
                                            attributes: { value: "Context" }.merge(attributes)).call
  end

  def admin_section(section_key)
    profile = StudentLearningProfiles::EnsureExists.new(actor: admin, student_profile: student).call
    StudentLearningProfiles::UpsertSection.new(actor: admin, profile:, section_key:).call
  end

  def admin_item(section, field_key)
    StudentLearningProfiles::UpsertItem.new(actor: admin, section:, field_key:,
                                            attributes: { value: "Protected" }).call
  end

  def teacher_item(section, field_key, attributes)
    StudentLearningProfiles::UpsertItem.new(actor: teacher, section:, field_key:,
                                            attributes: { value: "Context" }.merge(attributes)).call
  end
end
# rubocop:enable RSpec/ExampleLength
