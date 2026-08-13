require "rails_helper"

RSpec.describe FeePlan do
  it "is valid with default factory attributes" do
    expect(build(:fee_plan)).to be_valid
  end

  it "generates a public_id on create" do
    fee_plan = create(:fee_plan)
    expect(fee_plan.public_id).to match(/\AFEE-[A-Z0-9]{10}\z/)
  end

  it "requires billing_cycle to be one of the known cycles" do
    fee_plan = build(:fee_plan, billing_cycle: "yearly")
    expect(fee_plan).not_to be_valid
    expect(fee_plan.errors[:billing_cycle]).to be_present
  end

  it "rejects a negative amount" do
    expect(build(:fee_plan, amount: -1)).not_to be_valid
  end

  describe ".active" do
    it "returns only active fee plans" do
      active_plan = create(:fee_plan)
      create(:fee_plan, :inactive)
      expect(described_class.active).to contain_exactly(active_plan)
    end
  end

  it "nullifies the student's fee_plan_id when the fee plan is deleted" do
    fee_plan = create(:fee_plan)
    student = create(:student_profile, fee_plan:)
    fee_plan.destroy
    expect(student.reload.fee_plan_id).to be_nil
  end
end
