class CreateStaffProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_profiles do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }, index: { unique: true }
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :public_id, null: false
      t.string :display_name
      t.string :phone_number, null: false
      t.string :whatsapp_number, null: false
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :staff_profiles, :public_id, unique: true
  end
end
