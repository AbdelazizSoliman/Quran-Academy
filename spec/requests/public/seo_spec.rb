require "rails_helper"

RSpec.describe "Public SEO foundation" do
  let(:academy_setting) do
    create(:academy_setting, contact_email: "public@example.test", contact_phone: "+201000000000")
  end

  before { create(:public_website_setting, academy_setting:) }

  it "renders localized metadata, canonical, hreflang, OG, and safe organization JSON-LD" do
    get localized_public_home_path(locale: :en)
    expect(response.body).to include('<meta name="robots" content="index,follow">')
    expect(response.body).to include('rel="canonical" href="https://www.example.com/en"')
    expect(response.body).to include('hreflang="ar"', 'href="https://www.example.com/ar"', 'hreflang="en"')
    expect(response.body).to include('property="og:type" content="website"', 'property="og:locale" content="en_US"')
    expect(response.body).to include('"@type":"EducationalOrganization"', '"name":"Khadijah Academy"')
    expect(response.body).not_to include("StudentProfile", "guardian_id", "teacher_id")
  end

  it "marks private application pages noindex" do
    get dashboard_path
    expect(response).to redirect_to(new_user_session_path)
    follow_redirect!
    expect(response.body).to include('<meta name="robots" content="noindex,nofollow">')
  end

  it "renders FAQ JSON-LD only from visible localized FAQs" do
    create(:public_faq, :published, question_en: "Visible question", answer_en: "Visible answer")
    create(:public_faq, question_en: "Private question", answer_en: "Private answer")
    get public_faqs_path(locale: :en)
    expect(response.body).to include('"@type":"FAQPage"', "Visible question", "Visible answer")
    expect(response.body).not_to include("Private question", "Private answer")
  end
end
