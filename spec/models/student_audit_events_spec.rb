require "rails_helper"

RSpec.describe "Student and guardian audit events" do
  it "validates event types and rejects secret-like keys recursively" do
    [build(:student_profile_event), build(:guardian_event), build(:student_guardianship_event)].each do |event|
      event.event_type = "unknown"
      expect(event).not_to be_valid
      event.event_type = event.class::EVENT_TYPES.first
      event.metadata = { "changes" => [{ "password_token" => "secret" }] }
      expect(event).not_to be_valid
    end
  end
end
