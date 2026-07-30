require "rails_helper"

RSpec.describe "Academic catalog services" do
  let(:admin) { create(:user, :admin) }

  before { AcademySetting.current.update!(teaching_languages: %w[ar en]) }

  it "creates and audits programs" do
    program = Admin::Programs::Create.new(actor: admin, attributes: attributes_for(:program)).call
    expect(program).to be_persisted
    expect(program.events.pluck(:event_type)).to eq(["created"])
  end

  it "opens only offerings belonging to active programs" do
    offering = create(:course_offering)
    result = Admin::CourseOfferings::Transition.new(actor: admin, offering:, action: :open).call
    expect(result).to be_open
    expect(result.events.last.event_type).to eq("opened")
  end

  it "approves eligible adults transactionally" do
    profile = create(:student_profile, :complete, profile_status: "verified")
    offering = create(:course_offering, :open, capacity: 1)
    enrollment = create(:enrollment, student_profile: profile, course_offering: offering)
    result = Admin::Enrollments::Transition.new(actor: admin, enrollment:, action: :approve).call
    expect(result).to be_approved
    expect(result.events.last.event_type).to eq("approved")
  end

  it "refuses approval beyond capacity" do
    offering = create(:course_offering, :open, capacity: 1)
    create(:enrollment, :approved, course_offering: offering)
    pending = create(:enrollment, course_offering: offering)
    result = Admin::Enrollments::Transition.new(actor: admin, enrollment: pending, action: :approve).call
    expect(result).to be_pending
    expect(result.errors).not_to be_empty
  end

  it "requires placement before activation" do
    profile = create(:student_profile, :complete, profile_status: "verified")
    offering = create(:course_offering, :open, placement_required: true)
    enrollment = create(:enrollment, :approved, student_profile: profile, course_offering: offering,
                                                placement_status: "pending")
    result = Admin::Enrollments::Transition.new(actor: admin, enrollment:, action: :activate).call
    expect(result).to be_approved
    expect(result.errors).not_to be_empty
  end
end
