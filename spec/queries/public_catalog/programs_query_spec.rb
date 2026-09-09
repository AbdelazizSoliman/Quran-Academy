require "rails_helper"

RSpec.describe PublicCatalog::ProgramsQuery do
  before { create(:academy_setting) }

  it "returns only published and active programs in deterministic public order" do
    first = create(:program, :published, public_display_order: 1, name_en: "Beta", name_ar: "باء")
    second = create(:program, :published, public_display_order: 1, name_en: "Alpha", name_ar: "ألف")
    third = create(:program, :published, public_display_order: 0)
    create(:program, :active)

    expect(described_class.new(locale: "en").index.map(&:name_en))
      .to eq([third.name_en, second.name_en, first.name_en])
  end

  it "limits featured results to published featured programs" do
    featured = create(:program, :published, :featured)
    create(:program, :published)
    create(:program, :featured, :published).update!(published: false)

    expect(described_class.new(locale: "ar").featured).to contain_exactly(featured)
    expect(described_class.new(locale: "ar").featured(limit: 0)).to be_empty
  end

  it "looks a program up by the slug of the requested locale only" do
    program = create(:program, :published, slug_ar: "أساسيات", slug_en: "foundations")

    expect(described_class.new(locale: "en").find_published_by_slug("foundations")).to eq(program)
    expect(described_class.new(locale: "ar").find_published_by_slug("أساسيات")).to eq(program)
    expect(described_class.new(locale: "en").find_published_by_slug("أساسيات")).to be_nil
    expect(described_class.new(locale: "ar").find_published_by_slug("foundations")).to be_nil
    expect(described_class.new(locale: "en").find_published_by_slug(program.id.to_s)).to be_nil
  end

  it "selects only publicly approved columns" do
    create(:program, :published)

    record = described_class.new(locale: "en").index.first

    expect(record.attributes.keys).to match_array(described_class::PUBLIC_COLUMNS.map(&:to_s))
    expect { record.internal_notes }.to raise_error(ActiveModel::MissingAttributeError)
    expect { record.public_id }.to raise_error(ActiveModel::MissingAttributeError)
  end
end
