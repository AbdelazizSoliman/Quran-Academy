class CreatePublicWebsiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :public_website_settings do |t|
      t.references :academy_setting, null: false, foreign_key: true, index: { unique: true }
      t.boolean :enabled, null: false, default: false
      t.string :academy_name_ar, null: false, default: "أكاديمية خديجه"
      t.string :academy_name_en, null: false, default: "Khadijah Academy"
      t.string :hero_title_ar, null: false, default: "تعلّمي القرآن والعربية بثقة"
      t.string :hero_title_en, null: false, default: "Learn Quran and Arabic with confidence"
      t.text :hero_subtitle_ar
      t.text :hero_subtitle_en
      t.text :about_text_ar
      t.text :about_text_en
      t.string :primary_cta_label_ar, null: false, default: "ابدئي رحلتك"
      t.string :primary_cta_label_en, null: false, default: "Start your journey"
      t.string :primary_cta_url, null: false, default: "/account/sign-in"
      t.boolean :whatsapp_cta_enabled, null: false, default: false
      t.boolean :public_email_enabled, null: false, default: false
      t.boolean :public_phone_enabled, null: false, default: false
      t.boolean :public_whatsapp_enabled, null: false, default: false

      t.timestamps
    end
  end
end
