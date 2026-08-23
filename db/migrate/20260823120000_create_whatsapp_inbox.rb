class CreateWhatsappInbox < ActiveRecord::Migration[8.1]
  def change
    create_table :whatsapp_conversations do |t|
      t.string :public_id, null: false
      t.string :sender_phone, null: false
      t.string :sender_name
      t.references :contact, polymorphic: true, null: true
      t.string :status, null: false, default: "open"
      t.integer :unread_count, null: false, default: 0
      t.datetime :last_message_at, null: false
      t.datetime :read_at
      t.timestamps

      t.index :public_id, unique: true
      t.index :sender_phone, unique: true
      t.index %i[status last_message_at]
      t.check_constraint "status IN ('open','archived')", name: "whatsapp_conversations_status"
      t.check_constraint "unread_count >= 0", name: "whatsapp_conversations_unread_count"
    end

    create_table :whatsapp_messages do |t|
      t.references :whatsapp_conversation, null: false, foreign_key: { on_delete: :restrict }
      t.string :public_id, null: false
      t.string :provider_message_id, null: false
      t.string :direction, null: false, default: "inbound"
      t.string :message_type, null: false
      t.text :body
      t.datetime :received_at, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps

      t.index :public_id, unique: true
      t.index :provider_message_id, unique: true
      t.index %i[whatsapp_conversation_id received_at], name: "idx_whatsapp_messages_conversation_received"
      t.check_constraint "direction IN ('inbound','outbound')", name: "whatsapp_messages_direction"
    end
  end
end
