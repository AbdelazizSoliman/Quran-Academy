require "rails_helper"

RSpec.describe "Admin finance" do
  let(:admin) { create(:user, :admin) }

  it "allows an administrator to create and issue an invoice" do
    student = create(:student_profile, :complete)
    sign_in admin

    post admin_finance_invoices_path, params: { finance_invoice: invoice_attributes(student) }
    invoice = FinanceInvoice.last
    expect(response).to redirect_to(admin_finance_invoice_path(invoice))

    patch issue_admin_finance_invoice_path(invoice)
    expect(invoice.reload).to be_issued
  end

  it "renders financial reports and exports CSV" do
    sign_in admin

    get admin_financial_reports_path
    expect(response).to have_http_status(:ok)

    get export_admin_financial_report_path("revenue")
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
  end

  it "records invoice payments through the admin workflow" do
    invoice = create(:finance_invoice, :issued, created_by: admin, updated_by: admin)
    sign_in admin

    post admin_finance_invoice_payments_path(invoice), params: {
      finance_payment: { amount: 200, received_on: Date.current, payment_method: "bank_transfer" }
    }

    expect(response).to redirect_to(admin_finance_invoice_path(invoice))
    expect(invoice.reload).to be_partially_paid
  end

  it "creates, approves, and pays an expense" do
    sign_in admin
    post admin_finance_expenses_path, params: { finance_expense: expense_attributes }
    expense = FinanceExpense.last
    expect(response).to redirect_to(admin_finance_expense_path(expense))

    patch approve_admin_finance_expense_path(expense)
    patch pay_admin_finance_expense_path(expense)
    expect(expense.reload.status).to eq("paid")
  end

  it "renders all finance index and detail pages" do
    invoice = create(:finance_invoice)
    expense = create(:finance_expense)
    sign_in admin

    [admin_finance_invoices_path, admin_finance_invoice_path(invoice), new_admin_finance_invoice_path,
     admin_finance_expenses_path, admin_finance_expense_path(expense), new_admin_finance_expense_path,
     admin_finance_ledger_entries_path].each do |path|
      get path
      expect(response).to have_http_status(:ok)
    end
  end

  it "forbids non-admin users from finance records" do
    sign_in create(:user, :staff)

    get admin_finance_invoices_path

    expect(response).to have_http_status(:forbidden)
  end

  def invoice_attributes(student)
    { student_profile_id: student.id, billing_period_starts_on: Date.current.beginning_of_month,
      billing_period_ends_on: Date.current.end_of_month, due_on: Date.current + 7.days,
      currency: "EGP", subtotal: 500, discount_amount: 0, tax_amount: 0 }
  end

  def expense_attributes
    { category: "technology", description: "Subscription", amount: 100, currency: "EGP",
      incurred_on: Date.current, payment_method: "bank_transfer" }
  end
end
