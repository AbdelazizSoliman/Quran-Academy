class ExpandStudentTeacherOnboarding < ActiveRecord::Migration[8.1]
  def change
    change_table :student_profiles, bulk: true do |t|
      t.decimal :wallet_balance, precision: 12, scale: 2, default: 0, null: false
      t.decimal :discount_percentage, precision: 5, scale: 2, default: 0, null: false
      t.references :assigned_teacher_profile, foreign_key: { to_table: :teacher_profiles }, index: true
      t.string :package_name
      t.integer :weekly_lesson_count
      t.integer :lesson_duration_minutes
      t.integer :sessions_per_month
      t.string :session_type, default: "individual", null: false
      t.datetime :trial_lesson_at
      t.string :schedule_weekday
      t.time :schedule_time
      t.jsonb :schedule_slots, default: [], null: false
      t.references :sibling_student_profile, foreign_key: { to_table: :student_profiles }, index: true
      t.decimal :weekly_price, precision: 12, scale: 2, default: 0, null: false
      t.string :billing_currency, default: "EGP", null: false
      t.string :guardian_name
      t.string :guardian_email
      t.string :guardian_phone
      t.string :account_delivery_method, default: "whatsapp", null: false
    end

    change_table :teacher_profiles, bulk: true do |t|
      t.string :notification_method, default: "whatsapp", null: false
      t.string :message_language, default: "ar", null: false
      t.integer :workload_percentage, default: 0, null: false
      t.boolean :on_leave, default: false, null: false
      t.string :work_days, array: true, default: [], null: false
      t.time :work_start_time
      t.time :work_end_time
      t.decimal :monthly_salary, precision: 12, scale: 2, default: 0, null: false
      t.boolean :mid_period_previous_dues, default: false, null: false
    end

    add_check_constraint :student_profiles, "wallet_balance >= 0", name: "student_profiles_wallet_nonnegative"
    add_check_constraint :student_profiles, "discount_percentage >= 0 AND discount_percentage <= 100", name: "student_profiles_discount_range"
    add_check_constraint :student_profiles, "weekly_price >= 0", name: "student_profiles_weekly_price_nonnegative"
    add_check_constraint :teacher_profiles, "workload_percentage >= 0 AND workload_percentage <= 100", name: "teacher_profiles_workload_range"
    add_check_constraint :teacher_profiles, "monthly_salary >= 0", name: "teacher_profiles_monthly_salary_nonnegative"
  end
end
