require "rails_helper"

# This file exercises the three catalog aggregates together.
# rubocop:disable RSpec/DescribeClass
RSpec.describe "Academic catalog models" do
  before { AcademySetting.current.update!(teaching_languages: %w[ar en]) }

  it "normalizes program codes and creates immutable public identifiers" do
    program = create(:program, code: " taj-core ")
    expect(program.code).to eq("TAJ-CORE")
    expect(program.public_id).to match(/\APRG-[A-Z0-9]{10}\z/)
    expect { program.update!(public_id: "PRG-AAAAAAAAAA") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect(program.reload.public_id).not_to eq("PRG-AAAAAAAAAA")
  end

  it "validates languages and age eligibility" do
    program = build(:program, default_learning_language: "fr", supported_learning_languages: %w[fr],
                              allows_minor_students: false, target_age_groups: %w[children])
    expect(program).not_to be_valid
  end

  it "snapshots program defaults on a new offering" do
    program = create(:program, :active, :placement_required, default_learning_language: "ar",
                                                             target_age_groups: %w[adults])
    offering = create(:course_offering, program:, learning_language: "", target_age_groups: [])
    expect(offering).to have_attributes(learning_language: "ar", target_age_groups: %w[adults],
                                        placement_required: true)
  end

  it "rejects incompatible offering languages and invalid dates" do
    offering = build(:course_offering, learning_language: "fr",
                                       enrollment_opens_on: Date.current,
                                       enrollment_closes_on: 1.day.ago)
    expect(offering).not_to be_valid
  end

  it "prevents duplicate enrollment membership and snapshots placement" do
    student = create(:student_profile, :complete, learning_goals: "Memorize")
    offering = create(:course_offering, :open)
    enrollment = create(:enrollment, student_profile: student, course_offering: offering)
    duplicate = build(:enrollment, student_profile: student, course_offering: offering)
    expect(enrollment.student_goals_snapshot).to eq("Memorize")
    expect(duplicate).not_to be_valid
  end

  it "rejects unsafe event metadata" do
    event = build(:program_event, metadata: { changes: { token: "unsafe" } })
    expect(event).not_to be_valid
  end
end
# rubocop:enable RSpec/DescribeClass
