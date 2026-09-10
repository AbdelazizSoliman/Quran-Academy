class AddSeoDefaultsToPublicWebsiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :public_website_settings, :seo_title_ar, :string
    add_column :public_website_settings, :seo_title_en, :string
    add_column :public_website_settings, :seo_description_ar, :text
    add_column :public_website_settings, :seo_description_en, :text
  end
end
