class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.string :public_id, null: false
      t.references :recipient_user, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :source_type
      t.bigint :source_id
      t.string :channel, null: false
      t.string :notification_type, null: false
      t.string :status, null: false, default: "pending"
      t.string :recipient_address_masked, null: false
      t.string :recipient_locale, null: false
      t.string :subject
      t.text :message_snapshot, null: false
      t.string :provider_message_id
      t.jsonb :provider_response, null: false, default: {}
      t.string :failure_code
      t.text :failure_reason
      t.integer :attempt_count, null: false, default: 0
      t.integer :retry_count, null: false, default: 0
      t.datetime :first_attempted_at
      t.datetime :last_attempted_at
      t.datetime :sent_at
      t.datetime :failed_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :notifications, :public_id, unique: true
    add_index :notifications, %i[source_type source_id]
    add_index :notifications, %i[recipient_user_id created_at]
    add_index :notifications, %i[channel status created_at]
    add_index :notifications, :provider_message_id
    add_check_constraint :notifications, "channel IN ('email','whatsapp')", name: "notification_channel"
    add_check_constraint :notifications, "status IN ('pending','sending','sent','failed')",
                         name: "notification_status"
    add_check_constraint :notifications, "retry_count >= 0", name: "notification_retry_count"
    add_check_constraint :notifications, "attempt_count >= 0", name: "notification_attempt_count"

    create_table :notification_events do |t|
      t.references :notification, null: false, foreign_key: { on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :event_type, null: false
      t.jsonb :before_data, null: false, default: {}
      t.jsonb :after_data, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :notification_events, %i[notification_id created_at], name: "idx_notification_event_history"
  end
end
