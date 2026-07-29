require "rails_helper"

RSpec.describe StudentGuardianship do
  it "validates relationship catalogs, custom relationships, and dates" do
    link = build(:student_guardianship, relationship_type: "other", custom_relationship: nil,
                                        starts_on: Date.current, ends_on: Date.yesterday)
    expect(link).not_to be_valid
    expect(link.errors).to include(:custom_relationship, :ends_on)
  end

  it "prevents duplicate active relationships" do
    link = create(:student_guardianship)
    duplicate = build(:student_guardianship, student_profile: link.student_profile,
                                             guardian: link.guardian,
                                             relationship_type: link.relationship_type)
    expect(duplicate).not_to be_valid
  end

  it "requires an end date for ended relationships" do
    expect(build(:student_guardianship, status: "ended", ends_on: nil)).not_to be_valid
  end
end
