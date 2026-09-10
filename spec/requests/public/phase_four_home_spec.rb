require "rails_helper"

RSpec.describe "Phase 4 homepage" do
  let(:academy_setting) { create(:academy_setting) }

  before { create(:public_website_setting, academy_setting:) }

  it "keeps trust, fees, trial, contact, and conditional programs intact" do
    create(:fee_plan, :published, name_en: "Clear Plan")
    get localized_public_home_path(locale: :en)
    expect(response.body).to include('id="trust-values"', "Clear Plan", public_trial_path(locale: :en),
                                     public_contact_path(locale: :en))
    expect(response.body).not_to include('id="programs"')
  end

  it "hides testimonial and FAQ sections when empty" do
    get localized_public_home_path(locale: :en)
    expect(response.body).not_to include('id="testimonials"', 'id="faq"')
  end

  it "shows only three published testimonials in display order with safe labels" do
    4.times do |index|
      create(:public_testimonial, :published, author_name: nil, relationship: "Parent #{index}",
                                              quote_en: "Quote #{index}", public_display_order: index)
    end
    create(:public_testimonial, quote_en: "Private quote")
    get localized_public_home_path(locale: :en)
    expect(response.body).to include('id="testimonials"', "Quote 0", "Quote 1", "Quote 2", "Parent 0")
    expect(response.body).not_to include("Quote 3", "Private quote")
    expect(response.body.index("Quote 0")).to be < response.body.index("Quote 1")
  end

  it "shows at most five published FAQ previews and links the full page" do
    6.times { |index| create(:public_faq, :published, question_en: "FAQ #{index}", public_display_order: index) }
    create(:public_faq, question_en: "Private FAQ")
    get localized_public_home_path(locale: :en)
    expect(response.body).to include('id="faq"', "FAQ 0", "FAQ 4", public_faqs_path(locale: :en))
    expect(response.body).not_to include("FAQ 5", "Private FAQ")
  end

  it "does not leak English testimonial or FAQ copy into Arabic" do
    create(:public_testimonial, :published, quote_ar: "رأي عربي", quote_en: "English quote")
    create(:public_faq, :published, question_ar: "سؤال عربي", question_en: "English FAQ")
    get localized_public_home_path(locale: :ar)
    expect(response.body).to include("رأي عربي", "سؤال عربي")
    expect(response.body).not_to include("English quote", "English FAQ")
  end
end
