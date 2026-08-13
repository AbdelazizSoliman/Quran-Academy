class AddUserToGuardians < ActiveRecord::Migration[8.0]
  def change
    add_reference :guardians, :user, foreign_key: { on_delete: :restrict }, index: { unique: true }
  end
end
