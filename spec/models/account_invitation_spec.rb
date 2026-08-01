require "rails_helper"

RSpec.describe AccountInvitation do
  it "generates an immutable public ID and validates its lifecycle" do
    invitation = create(:account_invitation)

    expect(invitation.public_id).to match(/\AINV-[A-Z0-9]{10}\z/)
    expect { invitation.update!(public_id: "INV-AAAAAAAAAA") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect(invitation.reload.public_id).not_to eq("INV-AAAAAAAAAA")
    expect(described_class::STATUSES).to eq(%w[pending sent accepted expired cancelled])
  end

  it "allows only one invitation per user" do
    invitation = create(:account_invitation)
    duplicate = build(:account_invitation, user: invitation.user)

    expect(duplicate).not_to be_valid
  end

  it "never exposes a raw token column" do
    expect(described_class.column_names).not_to include("token")
  end
end
