class PublicWebsiteSetting < ApplicationRecord
  OFFICIAL_NAME_AR = "أكاديمية خديجه".freeze
  OFFICIAL_NAME_EN = "Khadijah Academy".freeze

  belongs_to :academy_setting

  validates :academy_setting_id, uniqueness: true
  validates :academy_name_ar, :academy_name_en, :hero_title_ar, :hero_title_en,
            :primary_cta_label_ar, :primary_cta_label_en, presence: true, length: { maximum: 200 }
  validates :hero_subtitle_ar, :hero_subtitle_en, :about_text_ar, :about_text_en,
            length: { maximum: 2_000 }, allow_blank: true
  validates :primary_cta_url, presence: true, length: { maximum: 500 },
                              format: { with: %r{\A(?:/[^/]?|https?://)[^\s]*\z} }

  def self.defaults
    {
      academy_name_ar: OFFICIAL_NAME_AR,
      academy_name_en: OFFICIAL_NAME_EN,
      hero_title_ar: "تعلّمي القرآن والعربية بثقة",
      hero_title_en: "Learn Quran and Arabic with confidence",
      primary_cta_label_ar: "ابدئي رحلتك",
      primary_cta_label_en: "Start your journey",
      primary_cta_url: "/account/sign-in"
    }
  end
end
