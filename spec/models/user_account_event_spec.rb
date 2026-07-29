require "rails_helper"

RSpec.describe UserAccountEvent do
  it "is valid with required associations and defaults metadata" do
    event = build(:user_account_event, metadata: nil)
    event.metadata = {}

    expect(event).to be_valid
  end

  it "rejects unknown event types" do
    expect(build(:user_account_event, event_type: "deleted")).not_to be_valid
  end

  it "rejects sensitive metadata keys" do
    event = build(:user_account_event, metadata: { changes: { password: "secret" } })

    expect(event).not_to be_valid
  end
end
