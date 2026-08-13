require "rails_helper"

RSpec.describe ReleaseFeatures do
  around do |example|
    keys = described_class::FEATURES.map { |feature| "FEATURE_#{feature.to_s.upcase}" }
    original = ENV.to_h.slice(*keys)
    keys.each { |key| ENV.delete(key) }
    example.run
  ensure
    keys.each { |key| ENV.delete(key) }
    original.each { |key, value| ENV[key] = value }
  end

  it "accepts explicit feature settings" do
    ENV["FEATURE_EXAMS"] = "false"
    ENV["FEATURE_CERTIFICATES"] = "true"

    expect(described_class.enabled?(:exams)).to be(false)
    expect(described_class.enabled?(:certificates)).to be(true)
  end

  it "rejects unknown features" do
    expect { described_class.enabled?(:finance) }.to raise_error(ArgumentError, /unknown release feature/)
  end
end
