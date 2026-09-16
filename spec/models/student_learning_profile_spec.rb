require "rails_helper"

RSpec.describe StudentLearningProfile do
  it "belongs one-to-one with a student and is not created automatically" do
    student = create(:student_profile)
    expect(student.student_learning_profile).to be_nil

    profile = create(:student_learning_profile, student_profile: student)
    expect(student.reload.student_learning_profile).to eq(profile)
    expect { create(:student_learning_profile, student_profile: student) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "exposes observations through the student without owning copied academic data" do
    profile = create(:student_learning_profile)
    observation = create(:student_observation, student_profile: profile.student_profile)
    expect(profile.observations).to contain_exactly(observation)
    expect(described_class.column_names).not_to include("student_name", "attendance_percentage", "quran_level")
  end
end
