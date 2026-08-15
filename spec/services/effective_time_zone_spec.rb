require "rails_helper"

RSpec.describe EffectiveTimeZone do
  it "uses the user, academy, then Rails application timezone fallback chain" do
    AcademySetting.current.update!(default_time_zone: "Riyadh")
    expect(described_class.for(build(:user, time_zone: "Cairo"))).to eq("Cairo")
    expect(described_class.for).to eq("Riyadh")

    allow(AcademySetting).to receive(:current_or_nil).and_return(nil)
    expect(described_class.for).to eq(Time.zone.name)
  end

  it "falls back safely for blank and unknown user timezones" do
    AcademySetting.current.update!(default_time_zone: "Riyadh")

    expect(described_class.for(build(:user, time_zone: nil))).to eq("Riyadh")
    expect(described_class.for(build(:user, time_zone: "Not/A-Time-Zone"))).to eq("Riyadh")
    expect { Time.current.in_time_zone(described_class.for(build(:user, time_zone: "Unknown"))) }.not_to raise_error
  end

  it "ignores an invalid academy timezone and falls back to Rails" do
    setting = AcademySetting.current
    allow(AcademySetting).to receive(:current_or_nil).and_return(setting)
    allow(setting).to receive(:default_time_zone).and_return("Unknown")

    expect(described_class.for).to eq(Time.zone.name)
  end
end
