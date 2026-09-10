require "rails_helper"

RSpec.describe PublicAnalyticsEvent do
  it "allows only supported event types and locales" do
    event = build(:public_analytics_event)
    expect(event).to be_valid
    event.event_type = "arbitrary"
    expect(event).not_to be_valid
  end

  it "does not accept private lead data fields" do
    expect(described_class.column_names).not_to include("email", "phone", "user_agent", "ip_address")
  end

  it "provides a ninety-day retention cutoff" do
    expect(described_class.retention_cutoff).to be_within(1.second).of(90.days.ago)
  end
end
