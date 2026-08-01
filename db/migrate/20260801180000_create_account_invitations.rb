class CreateAccountInvitations < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_settings, :invitation_expires_after_hours, :integer, null: false, default: 72

    create_table :account_invitations do |t|
      t.string :public_id, null: false
      t.references :user, null: false, index: { unique: true }, foreign_key: { on_delete: :restrict }
      t.string :token_digest, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :sent_at
      t.integer :resent_count, null: false, default: 0
      t.datetime :last_sent_at
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :accepted_ip
      t.string :accepted_user_agent, limit: 500
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :account_invitations, :public_id, unique: true
    add_index :account_invitations, :token_digest, unique: true
    add_index :account_invitations, %i[status expires_at]

    create_table :account_invitation_events do |t|
      t.references :account_invitation, null: false, foreign_key: { on_delete: :restrict }
      t.references :actor, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :event_type, null: false
      t.jsonb :before_data, null: false, default: {}
      t.jsonb :after_data, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :account_invitation_events, %i[account_invitation_id created_at],
              name: "idx_invitation_events_history"
    add_check_constraint :academy_settings, "invitation_expires_after_hours BETWEEN 1 AND 8760",
                         name: "academy_invitation_expiry_range"
    add_check_constraint :account_invitations, "resent_count >= 0", name: "invitation_resent_count_nonnegative"
  end
end
