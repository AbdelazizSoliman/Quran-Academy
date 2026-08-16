require "rails_helper"

RSpec.describe Finance::MonthlyTrendQuery do
  it "builds actual monthly cash trends independently by currency" do
    invoice = create(:finance_invoice, :issued, currency: "USD")
    create(:finance_payment, finance_invoice: invoice, currency: "USD", amount: 300)
    create(:finance_expense, status: "paid", currency: "USD", amount: 50, paid_at: Time.current)

    rows = described_class.new.call.fetch("USD")
    current = rows.find { |row| row.month == Date.current.beginning_of_month }

    expect(current).to have_attributes(collected: 300, expenses: 50, net_profit: 250)
  end
end
