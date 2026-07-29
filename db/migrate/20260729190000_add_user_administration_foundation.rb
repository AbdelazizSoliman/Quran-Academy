class AddUserAdministrationFoundation < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :preferred_locale, false, "ar"

    add_column :users, :approved_at, :datetime
    add_reference :users, :approved_by, foreign_key: { to_table: :users, on_delete: :nullify }
    add_column :users, :session_version, :integer, null: false, default: 0
    add_index :users, %i[status role created_at]

    create_table :user_account_events do |t|
      t.references :target_user, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :actor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :event_type, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :user_account_events, %i[target_user_id created_at]
    add_index :user_account_events, %i[actor_id created_at]
    add_index :user_account_events, :event_type
    add_check_constraint :users, "preferred_locale IN ('ar', 'en')", name: "users_preferred_locale"
    add_check_constraint :users, "session_version >= 0", name: "users_session_version_nonnegative"
  end
end
