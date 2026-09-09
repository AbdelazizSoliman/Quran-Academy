require "rails_helper"

RSpec.describe FeePlan do
  it "is valid with default factory attributes" do
    expect(build(:fee_plan)).to be_valid
  end

  it "generates a public_id on create" do
    fee_plan = create(:fee_plan)
    expect(fee_plan.public_id).to match(/\AFEE-[A-Z0-9]{10}\z/)
  end

  it "requires billing_cycle to be one of the known cycles" do
    fee_plan = build(:fee_plan, billing_cycle: "yearly")
    expect(fee_plan).not_to be_valid
    expect(fee_plan.errors[:billing_cycle]).to be_present
  end

  it "rejects a negative amount" do
    expect(build(:fee_plan, amount: -1)).not_to be_valid
  end

  describe ".active" do
    it "returns only active fee plans" do
      active_plan = create(:fee_plan)
      create(:fee_plan, :inactive)
      expect(described_class.active).to contain_exactly(active_plan)
    end
  end

  describe "public website publication" do
    it "is public only when it is both active and published" do
      published = create(:fee_plan, :published)
      inactive = create(:fee_plan, :published, :inactive)
      unpublished = create(:fee_plan)

      expect(described_class.publicly_visible).to contain_exactly(published)
      expect(inactive).not_to be_publicly_visible
      expect(unpublished).not_to be_publicly_visible
    end

    it "requires a public name in both locales before publishing" do
      fee_plan = build(:fee_plan, published: true, name_ar: "خطة", name_en: nil)

      expect(fee_plan).not_to be_valid
      expect(fee_plan.errors[:name_en]).to be_present
    end

    it "splits newline separated public features per locale and bounds them" do
      fee_plan = build(:fee_plan, :published, public_features_en: (1..12).map { |i| "Feature #{i}" }.join("\n"))

      expect(fee_plan.public_features("en").size).to eq(described_class::MAX_PUBLIC_FEATURES)
      expect(fee_plan.public_features("ar")).to eq(["حصص منتظمة", "متابعة أسبوعية"])
    end

    it "stamps published_at once and keeps it through an unpublish cycle" do
      fee_plan = create(:fee_plan, :published)
      first_published_at = fee_plan.published_at
      expect(first_published_at).to be_present

      fee_plan.update!(published: false)
      expect(fee_plan.reload.published_at).to eq(first_published_at)
    end
  end

  it "nullifies the student's fee_plan_id when the fee plan is deleted" do
    fee_plan = create(:fee_plan)
    student = create(:student_profile, fee_plan:)
    fee_plan.destroy
    expect(student.reload.fee_plan_id).to be_nil
  end
end
