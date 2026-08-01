require "rails_helper"

RSpec.describe TeacherPayroll do
  it "uses immutable public and ownership identity with a unique teacher period" do
    payroll = create(:teacher_payroll)
    expect(payroll.public_id).to match(/\APAY-/)
    expect(build(:teacher_payroll, teacher_profile: payroll.teacher_profile)).not_to be_valid
    expect { payroll.update!(teacher_profile_id: create(:teacher_profile).id) }
      .to raise_error(ActiveRecord::ReadonlyAttributeError)
  end

  it "calculates net compensation without accounting fields" do
    payroll = build(:teacher_payroll, base_amount: 1_000, bonus_amount: 100, deduction_amount: 50,
                                      manual_adjustment_amount: -25)
    payroll.recalculate_net
    expect(payroll.net_amount).to eq(1_025)
  end

  it "restricts deletion when audit history exists" do
    payroll = create(:teacher_payroll)
    create(:teacher_payroll_event, teacher_payroll: payroll)
    expect { payroll.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end
end
