class AddPublicWebsiteFieldsToPrograms < ActiveRecord::Migration[8.1]
  def change
    add_column :programs, :published, :boolean, null: false, default: false
    add_column :programs, :published_at, :datetime
    add_column :programs, :slug_ar, :string
    add_column :programs, :slug_en, :string
    add_column :programs, :public_featured, :boolean, null: false, default: false
    add_column :programs, :public_display_order, :integer, null: false, default: 0

    add_index :programs, :slug_ar, unique: true
    add_index :programs, :slug_en, unique: true
    add_index :programs, %i[published public_display_order], name: "index_programs_on_publication_order"

    add_check_constraint :programs, "public_display_order >= 0", name: "programs_public_display_order_nonnegative"
  end
end
