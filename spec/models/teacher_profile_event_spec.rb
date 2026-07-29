require "rails_helper"

RSpec.describe TeacherProfileEvent do
  it "requires supported event types and defaults metadata" do
    event = build(:teacher_profile_event, event_type: "unknown")
    expect(event).not_to be_valid
    expect(described_class.new.metadata).to eq({})
  end

  it "recursively rejects secret-like metadata" do
    event = build(:teacher_profile_event, metadata: { "changes" => [{ "password_token" => "secret" }] })

    expect(event).not_to be_valid
    expect(event.errors[:metadata]).to be_present
  end

  it "orders history newest first" do
    profile = create(:teacher_profile)
    old_event = create(:teacher_profile_event, teacher_profile: profile, created_at: 2.days.ago)
    new_event = create(:teacher_profile_event, teacher_profile: profile, created_at: 1.day.ago)

    expect(profile.events.recent_first).to eq([new_event, old_event])
  end
end
