require "rails_helper"

RSpec.describe Finance::RecurringInvoiceGeneration do
  let(:admin) { create(:user, :admin) }
  let(:fee_plan) { create(:fee_plan, amount: 500, tax_percentage: 10, invoice_day: 7) }
  let(:today) { Date.new(2026, 8, 7) }

  def generate(today: self.today)
    described_class.new(actor: admin, today:).call
  end

  describe "invoicing an active student on the plan's invoice day" do
    subject(:invoice) { generate.first }

    let!(:student) do
      create(:student_profile, :complete, fee_plan:, learning_status: "active", discount_percentage: 10)
    end

    it "creates a draft invoice for the correct student, plan, and period" do
      expect(invoice).to be_persisted.and be_draft
      expect(invoice.student_profile).to eq(student)
      expect(invoice.fee_plan).to eq(fee_plan)
      expect(invoice.billing_period_starts_on).to eq(today.beginning_of_month)
      expect(invoice.billing_period_ends_on).to eq(today.end_of_month)
    end

    it "applies the student discount and the plan tax to the fee amount" do
      expect(invoice.subtotal).to eq(500)
      expect(invoice.discount_amount).to eq(50)
      expect(invoice.tax_amount).to eq(45)
      expect(invoice.total_amount).to eq(495)
    end
  end

  it "does nothing when it is not the plan's invoice day" do
    create(:student_profile, :complete, fee_plan:, learning_status: "active")

    expect(generate(today: Date.new(2026, 8, 8))).to be_empty
    expect(FinanceInvoice.count).to eq(0)
  end

  it "skips inactive students, inactive plans, and non-monthly cycles" do
    create(:student_profile, :complete, fee_plan:, learning_status: "paused")
    weekly_plan = create(:fee_plan, billing_cycle: "weekly", invoice_day: 7)
    create(:student_profile, :complete, fee_plan: weekly_plan, learning_status: "active")
    inactive_plan = create(:fee_plan, :inactive, invoice_day: 7)
    create(:student_profile, :complete, fee_plan: inactive_plan, learning_status: "active")

    expect(generate).to be_empty
  end

  it "does not double-invoice a student already billed for the same period" do
    student = create(:student_profile, :complete, fee_plan:, learning_status: "active")
    create(:finance_invoice, student_profile: student, fee_plan:, created_by: admin, updated_by: admin,
                             billing_period_starts_on: today.beginning_of_month,
                             billing_period_ends_on: today.end_of_month)

    expect(generate).to be_empty
    expect(FinanceInvoice.where(student_profile: student).count).to eq(1)
  end

  it "clamps the invoice day to the last day of shorter months" do
    fee_plan.update!(invoice_day: 31)
    create(:student_profile, :complete, fee_plan:, learning_status: "active")

    expect(generate(today: Date.new(2026, 2, 28)).size).to eq(1)
  end
end
