require "rails_helper"

RSpec.describe Notification do
  it "generates an immutable public ID and validates provider catalogs" do
    notification = create(:notification)
    expect(notification.public_id).to match(/\ANOT-[A-Z0-9]{10}\z/)
    expect(Notification::CHANNELS).to eq(%w[email whatsapp])
    expect(Notification::STATUSES).to eq(%w[pending sending sent delivered failed])
  end

  it "retains audit history" do
    event = create(:notification_event)
    expect { event.notification.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end

  it "retains every delivery attempt" do
    attempt = create(:notification_attempt)
    expect { attempt.notification.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end
end
