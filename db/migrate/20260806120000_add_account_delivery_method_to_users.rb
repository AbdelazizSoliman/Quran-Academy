class AddAccountDeliveryMethodToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :account_delivery_method, :string, default: "email", null: false
  end
end
