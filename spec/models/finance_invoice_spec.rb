require "rails_helper"

RSpec.describe FinanceInvoice do
  it "calculates invoice totals and balances from completed payments" do
    invoice = create(:finance_invoice, subtotal: 500, discount_amount: 50, tax_amount: 20)
    create(:finance_payment, finance_invoice: invoice, amount: 200)

    expect(invoice.reload).to have_attributes(total_amount: 470)
    expect(invoice.paid_amount).to eq(200)
    expect(invoice.balance_due).to eq(270)
  end
end
