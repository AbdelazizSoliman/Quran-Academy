require "rails_helper"

RSpec.describe "Admin fee plans" do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  it "is reachable from the admin sidebar" do
    get root_path
    expect(response.body).to include(admin_fee_plans_path)
  end

  it "lists fee plans and creates a new one inline, independent of any program or course offering" do
    get admin_fee_plans_path
    expect(response).to have_http_status(:ok)

    expect do
      post admin_fee_plans_path, params: {
        fee_plan: { name: "Memorization Plan", amount: 400, currency: "EGP", billing_cycle: "monthly",
                    tax_percentage: 0, invoice_day: 7, active: true }
      }
    end.to change(FeePlan, :count).by(1)
    expect(response).to redirect_to(admin_fee_plans_path)
    expect(FeePlan.find_by(name: "Memorization Plan")).to be_present
  end

  it "edits and deletes an existing fee plan" do
    fee_plan = create(:fee_plan, amount: 400)

    patch admin_fee_plan_path(fee_plan), params: { fee_plan: { amount: 450, active: false } }
    fee_plan.reload
    expect(fee_plan.amount).to eq(450)
    expect(fee_plan).not_to be_active

    expect { delete admin_fee_plan_path(fee_plan) }.to change(FeePlan, :count).by(-1)
  end

  it "nullifies a student's assignment instead of blocking deletion" do
    fee_plan = create(:fee_plan)
    student = create(:student_profile, fee_plan:)

    delete admin_fee_plan_path(fee_plan)

    expect(student.reload.fee_plan_id).to be_nil
  end

  it "redirects unauthenticated users and forbids non-admin roles" do
    sign_out admin
    get admin_fee_plans_path
    expect(response).to redirect_to(new_user_session_path)

    sign_in create(:user, :student)
    get admin_fee_plans_path
    expect(response).to have_http_status(:forbidden)
  end
end
