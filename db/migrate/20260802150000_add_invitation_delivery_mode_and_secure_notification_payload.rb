class AddInvitationDeliveryModeAndSecureNotificationPayload < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_settings, :invitation_delivery_mode, :string, null: false, default: "email_only"
    add_check_constraint :academy_settings,
                         "invitation_delivery_mode IN ('email_only','whatsapp_only','email_and_whatsapp')",
                         name: "academy_settings_invitation_delivery_mode"

    add_column :notifications, :delivery_payload_ciphertext, :text
  end
end
