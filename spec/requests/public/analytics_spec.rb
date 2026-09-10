require "rails_helper"

RSpec.describe "Public analytics" do
  let(:academy_setting) { create(:academy_setting) }

  before { create(:public_website_setting, academy_setting:) }

  it "tracks public page views without exposing analytics records" do
    expect { get localized_public_home_path(locale: :en) }.to change(PublicAnalyticsEvent, :count).by(1)
    expect(PublicAnalyticsEvent.last).to have_attributes(event_type: "page_view", locale: "en", source_path: "home")
    expect(get(analytics_events_path)).to eq(404)
  end

  it "accepts only allowlisted click events" do
    expect do
      post analytics_events_path, params: { event: { event_type: "trial_cta_click", locale: "en",
                                                     source_path: "home", target: "trial" } }
    end.to change(PublicAnalyticsEvent, :count).by(1)
    expect do
      post analytics_events_path, params: { event: { event_type: "page_view", locale: "en" } }
    end.not_to change(PublicAnalyticsEvent, :count)
  end

  it "records a conversion only after a valid inquiry" do
    expect do
      post public_trial_path(locale: :en), params: {
        public_inquiry: { name: "Amina", phone: "01012345678", message: "Trial" }
      }
    end.to change { PublicAnalyticsEvent.where(event_type: "trial_submitted").count }.by(1)

    post public_trial_path(locale: :en), params: { public_inquiry: { name: "Amina" } }
    expect(PublicAnalyticsEvent.where(event_type: "trial_submitted").count).to eq(1)
  end
end
