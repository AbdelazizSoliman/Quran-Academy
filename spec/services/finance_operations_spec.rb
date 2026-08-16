require "rails_helper"

RSpec.describe "Finance operations" do
  let(:admin) { create(:user, :admin) }

  it "issues an invoice with balanced ledger entries" do
    invoice = create(:finance_invoice, created_by: admin, updated_by: admin)

    expect { Finance::InvoiceOperation.new(actor: admin, invoice:).issue }
      .to change(FinanceLedgerEntry, :count).by(2)

    expect(invoice.reload).to be_issued
    expect(invoice.ledger_entries.pluck(:direction, :amount)).to contain_exactly(["debit", 500], ["credit", 500])
  end

  it "records a partial payment and prevents overpayment" do
    invoice = create(:finance_invoice, :issued, created_by: admin, updated_by: admin)
    service = Finance::RecordPayment.new(actor: admin, invoice:,
                                         attributes: { amount: 200, received_on: Date.current,
                                                       payment_method: "bank_transfer" })

    expect { service.call }.to change(FinancePayment, :count).by(1).and change(FinanceLedgerEntry, :count).by(2)
    expect(invoice.reload).to be_partially_paid

    excessive = described_payment(invoice, admin, 301)
    expect(excessive).not_to be_persisted
    expect(excessive.errors[:amount]).to be_present
  end

  it "records paid expenses in the immutable ledger" do
    expense = create(:finance_expense, created_by: admin)
    operation = Finance::ExpenseOperation.new(actor: admin, expense:)
    operation.transition(:approve)

    expect { operation.transition(:pay) }.to change(FinanceLedgerEntry, :count).by(2)
    expect(expense.reload.status).to eq("paid")
  end

  def described_payment(invoice, admin, amount)
    Finance::RecordPayment.new(actor: admin, invoice:,
                               attributes: { amount:, received_on: Date.current,
                                             payment_method: "bank_transfer" }).call
  end
end
