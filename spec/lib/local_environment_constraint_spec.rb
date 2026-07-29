require "rails_helper"

RSpec.describe LocalEnvironmentConstraint do
  subject(:constraint) { described_class.new }

  it "allows the showcase in a local environment" do
    expect(constraint.matches?(nil)).to be(true)
  end

  it "rejects the showcase in production" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production"))

    expect(constraint.matches?(nil)).to be(false)
  end
end
