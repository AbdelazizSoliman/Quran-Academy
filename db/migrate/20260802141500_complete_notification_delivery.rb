class CompleteNotificationDelivery < ActiveRecord::Migration[8.1]
  def change
    add_reference :notifications, :recipient_guardian, foreign_key: { to_table: :guardians, on_delete: :restrict }
    add_column :notifications, :provider, :string
    add_column :notifications, :provider_status, :string
    add_column :notifications, :http_status, :integer
    add_column :notifications, :delivered_at, :datetime
    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE notifications
          SET provider = CASE channel WHEN 'whatsapp' THEN 'meta_whatsapp' ELSE 'resend' END
        SQL
      end
    end
    change_column_null :notifications, :provider, false
    add_check_constraint :notifications, "provider IN ('resend','meta_whatsapp')", name: "notification_provider"
    remove_check_constraint :notifications, name: "notification_status"
    add_check_constraint :notifications, "status IN ('pending','sending','sent','delivered','failed')",
                         name: "notification_status"

    create_table :notification_attempts do |t|
      t.references :notification, null: false, foreign_key: { on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.integer :attempt_number, null: false
      t.string :provider, null: false
      t.string :status, null: false, default: "sending"
      t.string :recipient_address_masked, null: false
      t.string :request_fingerprint, null: false
      t.integer :http_status
      t.string :provider_status
      t.string :provider_message_id
      t.jsonb :provider_response, null: false, default: {}
      t.string :error_code
      t.text :error_message
      t.datetime :attempted_at, null: false
      t.datetime :completed_at
      t.timestamps
    end
    add_index :notification_attempts, %i[notification_id attempt_number], unique: true,
                                                                        name: "idx_notification_attempt_number"
    add_index :notification_attempts, :provider_message_id
    add_check_constraint :notification_attempts, "attempt_number > 0", name: "notification_attempt_positive"
    add_check_constraint :notification_attempts, "status IN ('sending','sent','delivered','failed')",
                         name: "notification_attempt_status"

    add_column :academy_settings, :invitation_notifications_enabled, :boolean, null: false, default: true
    add_column :academy_settings, :lesson_report_notifications_enabled, :boolean, null: false, default: true
    add_column :academy_settings, :certificate_notifications_enabled, :boolean, null: false, default: true
  end
end
