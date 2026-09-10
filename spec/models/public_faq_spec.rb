require "rails_helper"

RSpec.describe PublicFaq do
  it "allows an incomplete draft but requires complete bilingual content to publish" do
    draft = build(:public_faq, question_en: nil, answer_ar: nil)
    expect(draft).to be_valid

    draft.published = true
    expect(draft).not_to be_valid
    expect(draft.errors).to include(:question_en, :answer_ar)
  end

  it "requires a nonnegative integer display order" do
    expect(build(:public_faq, public_display_order: -1)).not_to be_valid
    expect(build(:public_faq, public_display_order: 1.5)).not_to be_valid
  end

  it "scopes published records and orders deterministically" do
    second = create(:public_faq, :published, public_display_order: 2)
    first = create(:public_faq, :published, public_display_order: 1)
    create(:public_faq, published: false, public_display_order: 0)

    expect(described_class.publicly_visible.public_ordered).to eq([first, second])
  end
end
