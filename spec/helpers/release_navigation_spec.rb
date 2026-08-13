require "rails_helper"

RSpec.describe NavigationHelper do
  it "hides a module when its release feature is disabled" do
    user = instance_double(User, role: "admin")
    allow(ReleaseFeatures).to receive(:enabled?).and_call_original
    allow(ReleaseFeatures).to receive(:enabled?).with(:exams).and_return(false)

    expect(helper.navigation_items_for(user)).not_to have_key(:exams)
  end
end
