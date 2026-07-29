require "rails_helper"

RSpec.describe "Student profile operations" do
  let(:admin) { create(:user, :admin) }

  it "creates and audits a student profile without accepting ownership or public IDs" do
    user = create(:user, :student)
    profile = Admin::StudentProfiles::Create.new(
      actor: admin, user:, attributes: attributes_for(:student_profile).except(:user)
    ).call
    expect(profile).to be_persisted
    expect(profile.events.pluck(:event_type)).to eq(["created"])
  end

  it "masks sensitive updates and creates no event for a no-op" do
    profile = create(:student_profile)
    operation = ->(attrs) { Admin::StudentProfiles::Update.new(actor: admin, profile:, attributes: attrs).call }
    expect { operation.call(display_name: profile.display_name) }.not_to change(StudentProfileEvent, :count)
    operation.call(medical_notes: "private condition")
    expect(profile.events.last.metadata.dig("changes", "medical_notes")).to eq("changed" => true)
    expect(profile.events.last.metadata.to_s).not_to include("private condition")
  end

  it "rolls back the profile when auditing fails" do
    profile = create(:student_profile, display_name: "Original")
    allow(StudentProfileEvent).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
    Admin::StudentProfiles::Update.new(actor: admin, profile:, attributes: { display_name: "Changed" }).call
    expect(profile.reload.display_name).to eq("Original")
  end

  it "allows self-service safe fields but ignores administrative fields at its boundary" do
    profile = create(:student_profile, learning_status: "prospective")
    attributes = { display_name: "Safe", learning_status: "active" }.slice(:display_name)
    Student::Profiles::Update.new(actor: profile.user, profile:, attributes:).call
    expect(profile.reload.display_name).to eq("Safe")
    expect(profile.learning_status).to eq("prospective")
    expect(profile.events.last.event_type).to eq("self_updated")
  end
end
