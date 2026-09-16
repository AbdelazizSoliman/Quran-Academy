require "rails_helper"

RSpec.describe StudentObservation do
  it "is attributable, append-oriented, and defaults to internal visibility" do
    observation = create(:student_observation, sensitivity: "sensitive", visibility: nil)
    expect(observation.created_by).to eq(observation.teacher_profile.user)
    expect(observation.visibility).to eq("internal")
    expect { observation.update!(observation: "Rewritten") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect(observation.destroy).to be(false)
    expect(observation.errors.details[:base]).to include(error: :immutable)
  end

  it "validates category and content" do
    observation = build(:student_observation, category: "diagnosis", observation: nil)
    expect(observation).not_to be_valid
    expect(observation.errors).to include(:category, :observation)
  end

  it "requires an optional lesson to match both teacher and student" do
    lesson = create(:scheduled_lesson, :scheduled)
    other_student = create(:student_profile)
    observation = build(:student_observation, student_profile: other_student,
                                              teacher_profile: lesson.teacher_profile, scheduled_lesson: lesson)
    expect(observation).not_to be_valid
    expect(observation.errors[:scheduled_lesson]).to be_present
  end
end
