require "rails_helper"

RSpec.describe FinanceLedgerEntry do
  it "cannot be changed after creation" do
    invoice = create(:finance_invoice)
    entry = described_class.create!(source: invoice, actor: invoice.created_by, entry_type: "invoice_issued",
                                    account: "revenue", direction: "credit", amount: 500,
                                    currency: "EGP", occurred_on: Date.current)

    expect(entry).to be_readonly
    expect { entry.update!(amount: 1) }.to raise_error(ActiveRecord::ActiveRecordError)
  end
end
