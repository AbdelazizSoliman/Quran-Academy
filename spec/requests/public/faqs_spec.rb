require "rails_helper"

RSpec.describe "Public FAQs" do
  let(:academy_setting) { create(:academy_setting) }

  before { create(:public_website_setting, academy_setting:) }

  it "returns 404 and hides navigation when no published FAQ exists" do
    create(:public_faq, question_en: "Hidden question")
    get localized_public_home_path(locale: :en)
    expect(response.body).not_to include(public_faqs_path(locale: :en), "Hidden question")
    get public_faqs_path(locale: :en)
    expect(response).to have_http_status(:not_found)
  end

  it "renders published FAQs in order in English and excludes unpublished content" do
    create(:public_faq, :published, question_en: "Second EN", question_ar: "ثاني", public_display_order: 2)
    create(:public_faq, :published, question_en: "First EN", question_ar: "أول", public_display_order: 1)
    create(:public_faq, question_en: "Unpublished EN")
    get public_faqs_path(locale: :en)
    expect(response).to have_http_status(:ok)
    expect(response.body.index("First EN")).to be < response.body.index("Second EN")
    expect(response.body).not_to include("Unpublished EN", "أول", "ثاني")
  end

  it "renders only Arabic localized content" do
    create(:public_faq, :published, question_ar: "سؤال عربي", answer_ar: "جواب عربي", question_en: "English question",
                                    answer_en: "English answer")
    get public_faqs_path(locale: :ar)
    expect(response.body).to include("سؤال عربي", "جواب عربي", 'dir="rtl"')
    expect(response.body).not_to include("English question", "English answer")
  end

  it "keeps disabled website behavior" do
    academy_setting.public_website_setting.update!(enabled: false)
    create(:public_faq, :published, question_en: "Not exposed")
    get public_faqs_path(locale: :en)
    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).not_to include("Not exposed")
  end
end
