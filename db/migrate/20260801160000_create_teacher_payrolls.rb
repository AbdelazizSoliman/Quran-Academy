class CreateTeacherPayrolls < ActiveRecord::Migration[8.1]
  def change
    create_table :teacher_payrolls do |t|
      t.string :public_id, null: false
      t.references :teacher_profile, null: false, foreign_key: { on_delete: :restrict }
      t.date :period_starts_on, null: false
      t.date :period_ends_on, null: false
      t.string :calculation_strategy, null: false
      t.string :currency, null: false
      t.decimal :rate, precision: 12, scale: 2, null: false, default: 0
      t.decimal :base_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :bonus_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :deduction_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :manual_adjustment_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :net_amount, precision: 12, scale: 2, null: false, default: 0
      t.string :status, null: false, default: "draft"
      t.text :notes
      t.text :adjustment_reason
      t.datetime :prepared_at
      t.references :prepared_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :approved_at
      t.references :approved_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :paid_at
      t.references :paid_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :cancelled_at
      t.references :cancelled_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :cancellation_reason
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :updated_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :teacher_payrolls, :public_id, unique: true
    add_index :teacher_payrolls, %i[teacher_profile_id period_starts_on period_ends_on],
              unique: true, name: "idx_payroll_teacher_period"
    add_index :teacher_payrolls, %i[status period_starts_on period_ends_on], name: "idx_payroll_status_period"
    add_check_constraint :teacher_payrolls, "period_ends_on >= period_starts_on", name: "payroll_period_order"
    add_check_constraint :teacher_payrolls,
                         "base_amount >= 0 AND bonus_amount >= 0 AND deduction_amount >= 0 AND rate >= 0",
                         name: "payroll_nonnegative_amounts"

    create_table :teacher_payroll_items do |t|
      t.references :teacher_payroll, null: false, foreign_key: { on_delete: :restrict }
      t.references :scheduled_lesson, null: false, foreign_key: { on_delete: :restrict }
      t.integer :duration_minutes, null: false
      t.decimal :rate, precision: 12, scale: 2, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.timestamps
    end
    add_index :teacher_payroll_items, %i[teacher_payroll_id scheduled_lesson_id], unique: true,
                                                                                  name: "idx_payroll_lesson"
    add_check_constraint :teacher_payroll_items, "duration_minutes >= 0 AND rate >= 0 AND amount >= 0",
                         name: "payroll_items_nonnegative"

    create_table :teacher_payroll_events do |t|
      t.references :teacher_payroll, null: false, foreign_key: { on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :event_type, null: false
      t.jsonb :before_data, null: false, default: {}
      t.jsonb :after_data, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :teacher_payroll_events, %i[teacher_payroll_id created_at], name: "idx_payroll_events_history"
  end
end
