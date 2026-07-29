require "rails_helper"

RSpec.describe AcademySettingEvent do
  it "accepts the constrained event with JSON metadata" do
    expect(build(:academy_setting_event)).to be_valid
  end

  it "rejects unknown types and nested sensitive metadata" do
    event = build(:academy_setting_event, event_type: "deleted",
                                          metadata: { changes: { provider_secret: "unsafe" } })

    expect(event).not_to be_valid
    expect(event.errors).to include(:event_type, :metadata)
  end
end
