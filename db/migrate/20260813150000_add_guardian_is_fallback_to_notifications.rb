class AddGuardianIsFallbackToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_column :notifications, :guardian_is_fallback, :boolean, null: false, default: false
  end
end
