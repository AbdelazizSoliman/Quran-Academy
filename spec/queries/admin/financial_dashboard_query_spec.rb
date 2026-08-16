require "rails_helper"

RSpec.describe Admin::FinancialDashboardQuery do
  it "estimates revenue and profit independently for each currency" do
    egp_plan = create(:fee_plan, amount: 1_200, currency: "EGP", billing_cycle: "monthly")
    usd_plan = create(:fee_plan, amount: 25, currency: "USD", billing_cycle: "weekly")
    create(:student_profile, learning_status: "active", fee_plan: egp_plan,
                             billing_currency: "EGP", discount_percentage: 10)
    create(:student_profile, learning_status: "active", fee_plan: usd_plan, billing_currency: "USD")
    create(:student_profile, learning_status: "prospective", fee_plan: egp_plan, billing_currency: "EGP")
    create(:teacher_payroll, currency: "EGP", net_amount: 400)

    result = described_class.new(month: Date.current.strftime("%Y-%m")).call

    expect(result).to have_attributes(active_students: 2,
                                      revenue_by_currency: include("EGP" => 1_080, "USD" => 108.33))
    expect(result.payroll_by_currency.fetch("EGP")).to eq(400)
    expect(result.profit_by_currency).to include("EGP" => 680, "USD" => 108.33)
  end

  it "reports active students whose pricing cannot produce a monthly estimate" do
    package = create(:fee_plan, amount: 500, billing_cycle: "package")
    create(:student_profile, learning_status: "active", fee_plan: package, weekly_price: 0)
    create(:student_profile, learning_status: "active", fee_plan: nil, weekly_price: 0)

    result = described_class.new.call

    expect(result.students_without_pricing).to eq(2)
    expect(result.revenue_by_currency).to be_empty
  end

  it "counts approved payrolls and excludes cancelled payroll costs" do
    create(:teacher_payroll, status: "approved", net_amount: 300)
    create(:teacher_payroll, status: "cancelled", net_amount: 900)

    result = described_class.new.call

    expect(result.approved_payrolls).to eq(1)
    expect(result.payroll_by_currency.fetch("EGP")).to eq(300)
  end
end
