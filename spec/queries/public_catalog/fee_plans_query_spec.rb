require "rails_helper"

RSpec.describe PublicCatalog::FeePlansQuery do
  it "returns only published and active fee plans in deterministic public order" do
    first = create(:fee_plan, :published, public_display_order: 2)
    second = create(:fee_plan, :published, public_display_order: 1)
    create(:fee_plan, :published, :inactive)
    create(:fee_plan)

    expect(described_class.new(locale: "en").index).to eq([second, first])
  end

  it "selects only publicly approved columns" do
    create(:fee_plan, :published)

    record = described_class.new(locale: "ar").index.first

    expect(record.attributes.keys).to match_array(described_class::PUBLIC_COLUMNS.map(&:to_s))
    expect { record.tax_percentage }.to raise_error(ActiveModel::MissingAttributeError)
    expect { record.invoice_day }.to raise_error(ActiveModel::MissingAttributeError)
    expect { record.created_by_id }.to raise_error(ActiveModel::MissingAttributeError)
  end

  it "bounds featured results" do
    create_list(:fee_plan, 4, :published)

    expect(described_class.new(locale: "en").featured.size).to eq(described_class::FEATURED_LIMIT)
  end
end
