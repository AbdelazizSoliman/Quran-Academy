class AddPaymentWhatsappEnabledToAcademySettings < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_settings, :payment_whatsapp_enabled, :boolean, null: false, default: false
  end
end
