class CreateAcademySettings < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_settings do |t|
      t.string :singleton_key, null: false, default: "current"
      t.string :academy_name, null: false, default: "Quran Academy"
      t.string :legal_name
      t.string :short_name
      t.text :description
      t.string :contact_email
      t.string :contact_phone
      t.string :whatsapp_number
      t.string :website_url
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :state_or_region
      t.string :postal_code
      t.string :country_code, null: false, default: "EG"
      t.string :default_locale, null: false, default: "ar"
      t.string :supported_locales, array: true, null: false, default: %w[ar en]
      t.string :default_time_zone, null: false, default: "Cairo"
      t.string :teaching_languages, array: true, null: false, default: %w[ar en]
      t.string :working_days, array: true, null: false,
                              default: %w[saturday sunday monday tuesday wednesday thursday]
      t.time :day_starts_at, null: false, default: "08:00"
      t.time :day_ends_at, null: false, default: "22:00"
      t.integer :default_lesson_duration_minutes, null: false, default: 30
      t.integer :minimum_lesson_duration_minutes, null: false, default: 15
      t.integer :maximum_lesson_duration_minutes, null: false, default: 120
      t.integer :lesson_duration_step_minutes, null: false, default: 15
      t.integer :minimum_booking_notice_hours, null: false, default: 2
      t.integer :maximum_booking_window_days, null: false, default: 90
      t.integer :reschedule_notice_hours, null: false, default: 12
      t.integer :student_cancellation_notice_hours, null: false, default: 12
      t.integer :teacher_cancellation_notice_hours, null: false, default: 12
      t.integer :late_cancellation_window_hours, null: false, default: 2
      t.boolean :allow_student_self_cancellation, null: false, default: true
      t.boolean :allow_teacher_self_cancellation, null: false, default: false
      t.integer :student_late_after_minutes, null: false, default: 5
      t.integer :teacher_late_after_minutes, null: false, default: 5
      t.integer :absence_after_minutes, null: false, default: 15
      t.boolean :allow_manual_attendance_adjustment, null: false, default: true
      t.boolean :email_notifications_enabled, null: false, default: true
      t.boolean :whatsapp_notifications_enabled, null: false, default: false
      t.boolean :sms_notifications_enabled, null: false, default: false
      t.boolean :lesson_reminders_enabled, null: false, default: true
      t.boolean :attendance_notifications_enabled, null: false, default: true
      t.boolean :payment_notifications_enabled, null: false, default: false
      t.integer :lesson_reminder_hours_before, null: false, default: 24
      t.integer :second_lesson_reminder_minutes_before, null: false, default: 60
      t.string :default_teacher_compensation_type, null: false, default: "per_lesson"
      t.decimal :default_teacher_rate, precision: 12, scale: 2, null: false, default: 0
      t.string :payroll_currency, null: false, default: "EGP"
      t.string :payroll_period, null: false, default: "monthly"
      t.string :billing_currency, null: false, default: "EGP"
      t.decimal :default_lesson_price, precision: 12, scale: 2, null: false, default: 0
      t.string :billing_cycle, null: false, default: "monthly"
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end

    add_index :academy_settings, :singleton_key, unique: true
    add_check_constraint :academy_settings, "singleton_key = 'current'", name: "academy_settings_singleton"
    add_check_constraint :academy_settings, "day_starts_at < day_ends_at", name: "academy_settings_operating_hours"
    add_check_constraint :academy_settings,
                         "minimum_lesson_duration_minutes <= default_lesson_duration_minutes AND " \
                         "default_lesson_duration_minutes <= maximum_lesson_duration_minutes",
                         name: "academy_settings_lesson_duration_order"
    add_check_constraint :academy_settings, "default_teacher_rate >= 0 AND default_lesson_price >= 0",
                         name: "academy_settings_nonnegative_money"

    create_table :academy_setting_events do |t|
      t.references :academy_setting, null: false, foreign_key: { on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :event_type, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :academy_setting_events, %i[academy_setting_id created_at]
  end
end
