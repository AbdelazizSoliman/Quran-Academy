require "rails_helper"

RSpec.describe "Teacher payroll and operational reports" do
  let(:admin) { create(:user, :admin) }
  let(:payroll) { create(:teacher_payroll, status: "prepared") }

  it "allows admin payroll operations and staff read-only access" do
    sign_in admin
    patch approve_admin_teacher_payroll_path(payroll)
    expect(payroll.reload).to be_approved
    sign_out admin
    sign_in create(:user, :staff)
    get admin_teacher_payroll_path(payroll)
    expect(response).to have_http_status(:ok)
    patch mark_paid_admin_teacher_payroll_path(payroll)
    expect(response).to have_http_status(:forbidden)
  end

  it "isolates teacher payroll history" do
    sign_in payroll.teacher_profile.user
    get teacher_payroll_path(payroll)
    expect(response).to have_http_status(:ok)
    other = create(:teacher_payroll, status: "paid")
    get teacher_payroll_path(other)
    expect(response).to have_http_status(:not_found)
  end

  it "denies students payroll access" do
    sign_in create(:user, :student)
    get teacher_payrolls_path
    expect(response).to have_http_status(:forbidden)
  end

  it "serves staff reports and UTF-8 BOM CSV exports" do
    sign_in create(:user, :staff)
    get admin_operational_reports_path
    expect(response).to have_http_status(:ok)
    get export_admin_operational_report_path("lesson_completion")
    expect(response.body).to start_with("\uFEFF")
    expect(response.media_type).to eq("text/csv")
  end

  it "defines no payroll deletion route" do
    routes = Rails.application.routes.routes.select do |route|
      route.verb.to_s.include?("DELETE") && route.path.spec.to_s.include?("payroll")
    end
    expect(routes).to be_empty
  end
end
