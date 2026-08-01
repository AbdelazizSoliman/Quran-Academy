require "rails_helper"

RSpec.describe "Teacher payroll services" do
  let(:admin) { create(:user, :admin) }
  let(:teacher) { create(:teacher_profile, :active, :verified, default_lesson_rate: 120) }
  let!(:completed_lesson) do
    create(:scheduled_lesson, status: "completed", teacher_profile: teacher,
                              starts_at: Date.current.noon, ends_at: Date.current.noon + 90.minutes)
  end

  before do
    create(:scheduled_lesson, status: "cancelled", cancellation_reason: "Cancelled", teacher_profile: teacher,
                              starts_at: Date.current.noon + 2.hours, ends_at: Date.current.noon + 3.hours)
  end

  it "generates per-lesson payroll idempotently from completed lessons only" do
    payroll = generate("per_lesson")
    expect(payroll.items.pluck(:scheduled_lesson_id)).to eq([completed_lesson.id])
    expect(payroll.base_amount).to eq(120)
    expect { generate("per_lesson") }.not_to change(TeacherPayroll, :count)
  end

  it "calculates hourly and fixed monthly strategies" do
    expect(generate("hourly").base_amount).to eq(180)
    next_month = Date.current.next_month
    fixed = generate("monthly_fixed", from: next_month.beginning_of_month, to: next_month.end_of_month)
    expect(fixed.base_amount).to eq(120)
  end

  it "supports manual amounts and audited adjustments" do
    payroll = generate("manual_amount", amount: 500)
    TeacherPayrolls::Adjust.new(actor: admin, payroll:, reason: "Performance bonus",
                                attributes: { bonus_amount: 50, deduction_amount: 10,
                                              manual_adjustment_amount: -5 }).call
    expect(payroll.net_amount).to eq(535)
    expect(payroll.events.last).to have_attributes(event_type: "adjusted")
  end

  it "enforces prepare, approve, paid lifecycle and reopening reasons" do
    payroll = generate("per_lesson")
    transition(payroll, :prepare)
    transition(payroll, :approve)
    expect(transition(payroll, :pay)).to be_paid
    expect(payroll.events.pluck(:event_type)).to include("prepared", "approved", "paid")
  end

  it "allows only administrators and creates no duplicate transition audit" do
    payroll = generate("per_lesson")
    result = TeacherPayrolls::Transition.new(actor: teacher.user, payroll:, action: :prepare).call
    expect(result.errors).to be_present
    payroll.errors.clear
    transition(payroll, :prepare)
    expect { transition(payroll, :prepare) }.not_to change(TeacherPayrollEvent, :count)
  end

  private

  def generate(strategy, from: Date.current.beginning_of_month, to: Date.current.end_of_month, amount: nil)
    TeacherPayrolls::Generate.new(actor: admin, teacher_profile: teacher, period_starts_on: from,
                                  period_ends_on: to, strategy:, manual_base_amount: amount).call
  end

  def transition(payroll, action)
    TeacherPayrolls::Transition.new(actor: admin, payroll:, action:).call
  end
end
