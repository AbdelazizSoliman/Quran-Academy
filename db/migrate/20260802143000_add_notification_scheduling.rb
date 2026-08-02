class AddNotificationScheduling < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :idempotency_key, :string
    add_column :notifications, :scheduled_at, :datetime
    add_column :notifications, :queued_at, :datetime
    add_index :notifications, :idempotency_key, unique: true, where: "idempotency_key IS NOT NULL"
    add_index :notifications, %i[scheduled_at status]

    add_column :academy_settings, :lesson_reminder_minutes_before, :integer, null: false, default: 30
    add_column :academy_settings, :first_late_reminder_minutes, :integer, null: false, default: 10
    add_column :academy_settings, :second_late_reminder_minutes, :integer, null: false, default: 20
    add_column :academy_settings, :certificate_whatsapp_enabled, :boolean, null: false, default: false
    add_column :academy_settings, :lesson_report_whatsapp_enabled, :boolean, null: false, default: true

    add_check_constraint :academy_settings,
                         "lesson_reminder_minutes_before BETWEEN 0 AND 1440 " \
                         "AND first_late_reminder_minutes BETWEEN 0 AND 1440 " \
                         "AND second_late_reminder_minutes BETWEEN 0 AND 1440",
                         name: "academy_notification_reminder_ranges"
  end
end
