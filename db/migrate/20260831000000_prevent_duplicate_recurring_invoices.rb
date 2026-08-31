class PreventDuplicateRecurringInvoices < ActiveRecord::Migration[8.0]
  def change
    add_index :finance_invoices,
              %i[student_profile_id fee_plan_id billing_period_starts_on billing_period_ends_on],
              unique: true,
              where: "fee_plan_id IS NOT NULL AND status <> 'cancelled'",
              name: "unique_active_recurring_invoice_period"
  end
end
