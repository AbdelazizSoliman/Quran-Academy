require "rails_helper"

RSpec.describe Program do
  before { create(:academy_setting) }

  it "treats a program as public only when it is active and published" do
    published = create(:program, :published)
    inactive = create(:program, :published)
    inactive.update!(status: "inactive")
    unpublished = create(:program, :active)

    expect(described_class.publicly_visible).to contain_exactly(published)
    expect(published).to be_publicly_visible
    expect(inactive).not_to be_publicly_visible
    expect(unpublished).not_to be_publicly_visible
  end

  it "does not publish a program merely because it became active" do
    program = create(:program)

    Admin::Programs::Transition.new(actor: program.created_by, program:, action: :activate).call

    expect(program.reload).to have_attributes(status: "active", published: false, published_at: nil)
    expect(described_class.publicly_visible).to be_empty
  end

  it "requires complete bilingual public content before publishing" do
    program = build(:program, :active, published: true, short_description_en: nil, slug_ar: nil)

    expect(program).not_to be_valid
    expect(program.errors[:slug_ar]).to be_present
    expect(program.errors[:short_description_en]).to be_present
  end

  it "normalizes slugs and keeps them unique per locale" do
    create(:program, :published, slug_en: "quran-foundations", slug_ar: "أساسيات-القرآن")
    duplicate = build(:program, :published, slug_en: "  Quran   Foundations!! ")

    expect(duplicate).not_to be_valid
    expect(duplicate.slug_en).to eq("quran-foundations")
    expect(duplicate.errors[:slug_en]).to be_present
  end

  it "stamps published_at once and keeps it through an unpublish cycle" do
    program = create(:program, :active)
    expect(program.published_at).to be_nil

    program.update!(published: true, slug_ar: "برنامج-ا", slug_en: "program-a")
    first_published_at = program.published_at
    expect(first_published_at).to be_present

    program.update!(published: false)
    expect(program.reload.published_at).to eq(first_published_at)

    program.update!(published: true)
    expect(program.reload.published_at).to eq(first_published_at)
  end
end
