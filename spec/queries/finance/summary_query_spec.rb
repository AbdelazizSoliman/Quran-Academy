require "rails_helper"

RSpec.describe Finance::SummaryQuery do
  it "reports actual collections, costs, receivables, and profit per currency" do
    invoice = create(:finance_invoice, :issued, total_amount: 500)
    create(:finance_payment, finance_invoice: invoice, amount: 300)
    create(:finance_expense, status: "paid", amount: 50, paid_at: Time.current)
    create(:teacher_payroll, status: "paid", net_amount: 100, paid_at: Time.current)

    summary = described_class.new.call.by_currency.fetch("EGP")

    expect(summary).to include(collected: 300, outstanding: 200, payroll_paid: 100, expenses: 50,
                               net_profit: 150)
  end
end
