FactoryBot.define do
  factory :public_website_setting do
    association :academy_setting
    enabled { true }
    academy_name_ar { PublicWebsiteSetting::OFFICIAL_NAME_AR }
    academy_name_en { PublicWebsiteSetting::OFFICIAL_NAME_EN }
    hero_title_ar { "تعلّمي القرآن بثقة" }
    hero_title_en { "Learn Quran with confidence" }
    hero_subtitle_ar { "تعليم هادف في بيئة داعمة" }
    hero_subtitle_en { "Purposeful learning in a supportive environment" }
    about_text_ar { "نساند كل متعلّمة في رحلتها." }
    about_text_en { "We support every learner on her journey." }
    primary_cta_label_ar { "ابدئي رحلتك" }
    primary_cta_label_en { "Start your journey" }
    primary_cta_url { "/account/sign-in" }
  end
end
