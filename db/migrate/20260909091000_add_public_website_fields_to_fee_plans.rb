class AddPublicWebsiteFieldsToFeePlans < ActiveRecord::Migration[8.1]
  def change
    add_column :fee_plans, :published, :boolean, null: false, default: false
    add_column :fee_plans, :published_at, :datetime
    add_column :fee_plans, :name_ar, :string
    add_column :fee_plans, :name_en, :string
    add_column :fee_plans, :description_ar, :text
    add_column :fee_plans, :description_en, :text
    add_column :fee_plans, :public_features_ar, :text
    add_column :fee_plans, :public_features_en, :text
    add_column :fee_plans, :price_note_ar, :string
    add_column :fee_plans, :price_note_en, :string
    add_column :fee_plans, :public_cta_label_ar, :string
    add_column :fee_plans, :public_cta_label_en, :string
    add_column :fee_plans, :public_display_order, :integer, null: false, default: 0

    add_index :fee_plans, %i[published public_display_order], name: "index_fee_plans_on_publication_order"

    add_check_constraint :fee_plans, "public_display_order >= 0", name: "fee_plans_public_display_order_nonnegative"
  end
end
