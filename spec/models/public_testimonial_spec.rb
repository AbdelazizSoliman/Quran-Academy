require "rails_helper"

RSpec.describe PublicTestimonial do
  it "allows an incomplete draft but requires both localized quotes to publish" do
    draft = build(:public_testimonial, quote_en: nil)
    expect(draft).to be_valid
    draft.published = true
    expect(draft).not_to be_valid
    expect(draft.errors).to include(:quote_en)
  end

  it "requires a relationship fallback and nonnegative order" do
    expect(build(:public_testimonial, relationship: nil)).not_to be_valid
    expect(build(:public_testimonial, public_display_order: -1)).not_to be_valid
  end

  it "returns only published records in deterministic order" do
    second = create(:public_testimonial, :published, public_display_order: 2)
    first = create(:public_testimonial, :published, public_display_order: 1)
    create(:public_testimonial)
    expect(described_class.publicly_visible.public_ordered).to eq([first, second])
  end
end
