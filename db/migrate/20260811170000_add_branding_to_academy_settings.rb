class AddBrandingToAcademySettings < ActiveRecord::Migration[8.0]
  def change
    change_table :academy_settings, bulk: true do |table|
      table.string :logo_url
      table.string :primary_color, null: false, default: "#0B654F"
      table.string :secondary_color, null: false, default: "#A85D09"
      table.string :slug, null: false, default: "quran-academy"
      table.string :custom_domain
    end

    add_index :academy_settings, :slug, unique: true
  end
end
