require "rails_helper"

RSpec.describe StudentLearningProfileEvent do
  it "rejects section and item references from another profile" do
    event = build(:student_learning_profile_event)
    other_section = create(:student_learning_profile_section)
    other_item = create(:student_learning_profile_item, section: other_section)
    event.section = other_section
    event.item = other_item
    expect(event).not_to be_valid
    expect(event.errors).to include(:section, :item)
  end

  it "cannot be updated or destroyed" do
    event = create(:student_learning_profile_event)
    expect { event.update!(action: "section_created") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect(event.destroy).to be(false)
    expect(event.errors.details[:base]).to include(error: :immutable)
  end
end
