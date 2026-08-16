class CreateFinanceRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :finance_invoices do |t|
      t.string :public_id, null: false
      t.references :student_profile, null: false, foreign_key: { on_delete: :restrict }
      t.references :fee_plan, foreign_key: { on_delete: :nullify }
      t.date :billing_period_starts_on, null: false
      t.date :billing_period_ends_on, null: false
      t.date :issued_on
      t.date :due_on, null: false
      t.string :status, null: false, default: "draft"
      t.string :currency, null: false
      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :discount_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :tax_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total_amount, precision: 12, scale: 2, null: false, default: 0
      t.text :notes
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :updated_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.timestamps
    end
    add_index :finance_invoices, :public_id, unique: true
    add_index :finance_invoices, %i[status due_on]
    add_check_constraint :finance_invoices, "billing_period_ends_on >= billing_period_starts_on",
                         name: "finance_invoices_period_order"
    add_check_constraint :finance_invoices,
                         "subtotal >= 0 AND discount_amount >= 0 AND tax_amount >= 0 AND total_amount >= 0",
                         name: "finance_invoices_nonnegative_amounts"

    create_table :finance_payments do |t|
      t.string :public_id, null: false
      t.references :finance_invoice, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, null: false
      t.date :received_on, null: false
      t.string :payment_method, null: false
      t.string :reference
      t.string :status, null: false, default: "completed"
      t.text :notes
      t.datetime :refunded_at
      t.references :recorded_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :refunded_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :finance_payments, :public_id, unique: true
    add_index :finance_payments, %i[status received_on]
    add_check_constraint :finance_payments, "amount > 0", name: "finance_payments_positive_amount"

    create_table :finance_expenses do |t|
      t.string :public_id, null: false
      t.string :category, null: false
      t.string :vendor
      t.text :description, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, null: false
      t.date :incurred_on, null: false
      t.string :payment_method
      t.string :reference
      t.string :status, null: false, default: "draft"
      t.datetime :approved_at
      t.datetime :paid_at
      t.datetime :cancelled_at
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :approved_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :paid_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :cancelled_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :finance_expenses, :public_id, unique: true
    add_index :finance_expenses, %i[status incurred_on]
    add_check_constraint :finance_expenses, "amount > 0", name: "finance_expenses_positive_amount"

    create_table :finance_ledger_entries do |t|
      t.string :public_id, null: false
      t.string :entry_type, null: false
      t.string :account, null: false
      t.string :direction, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, null: false
      t.date :occurred_on, null: false
      t.string :source_type, null: false
      t.bigint :source_id, null: false
      t.text :description
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.timestamps
    end
    add_index :finance_ledger_entries, :public_id, unique: true
    add_index :finance_ledger_entries, %i[source_type source_id]
    add_index :finance_ledger_entries, %i[currency occurred_on]
    add_check_constraint :finance_ledger_entries, "amount > 0", name: "finance_ledger_entries_positive_amount"
  end
end
