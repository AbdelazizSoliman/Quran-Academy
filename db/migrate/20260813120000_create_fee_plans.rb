class CreateFeePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :fee_plans do |t|
      t.string :public_id, null: false
      t.string :name, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false, default: 0
      t.string :currency, null: false, default: "EGP"
      t.string :billing_cycle, null: false, default: "monthly"
      t.decimal :tax_percentage, precision: 5, scale: 2, null: false, default: 0
      t.integer :invoice_day, null: false, default: 7
      t.boolean :active, null: false, default: true
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :updated_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.timestamps
    end
    add_index :fee_plans, :public_id, unique: true
    add_index :fee_plans, :active
    add_check_constraint :fee_plans, "billing_cycle IN ('per_lesson','weekly','monthly','package')",
                         name: "fee_plan_billing_cycle"
    add_check_constraint :fee_plans, "tax_percentage BETWEEN 0 AND 100", name: "fee_plan_tax_percentage_range"
    add_check_constraint :fee_plans, "invoice_day BETWEEN 1 AND 31", name: "fee_plan_invoice_day_range"

    add_reference :student_profiles, :fee_plan, foreign_key: { on_delete: :nullify }
  end
end
