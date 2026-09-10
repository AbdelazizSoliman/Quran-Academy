require "rails_helper"
# rubocop:disable RSpec/SpecFilePathFormat

RSpec.describe PublicContent::FaqsQuery do
  it "allowlists FAQ columns and caps the full page at 100" do
    create_list(:public_faq, 101, :published)
    records = described_class.new.index
    expect(records.size).to eq(100)
    expect(records.first.attributes.keys).to match_array(PublicContent::FaqsQuery::PUBLIC_COLUMNS.map(&:to_s))
  end

  it "caps testimonials at three and uses the relationship when public author name is blank" do
    4.times do |index|
      create(:public_testimonial, :published, author_name: nil, relationship: "Parent #{index}",
                                              public_display_order: index)
    end
    records = PublicContent::TestimonialsQuery.new.homepage
    presenters = PublicContent::TestimonialPresenter.wrap(records, locale: :en)
    expect(presenters.map(&:author_label)).to eq(["Parent 0", "Parent 1", "Parent 2"])
    expect(records.first.attributes.keys).to match_array(PublicContent::TestimonialsQuery::PUBLIC_COLUMNS.map(&:to_s))
  end

  it "does not fall back between locales" do
    faq = build(:public_faq, question_ar: "عربي", question_en: nil)
    testimonial = build(:public_testimonial, quote_ar: "عربي", quote_en: nil)
    expect(PublicContent::FaqPresenter.new(faq, locale: :en).question).to be_nil
    expect(PublicContent::TestimonialPresenter.new(testimonial, locale: :en).quote).to be_nil
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
