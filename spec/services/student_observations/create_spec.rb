require "rails_helper"

# The linked-observation example intentionally covers both student and teacher context checks.
# rubocop:disable RSpec/ExampleLength
RSpec.describe StudentObservations::Create do
  let(:teacher_profile) { create(:teacher_profile, :active, :verified) }
  let(:student) { create(:student_profile, assigned_teacher_profile: teacher_profile) }

  it "lets an assigned teacher create an attributable observation" do
    observation = described_class.new(actor: teacher_profile.user, student_profile: student, teacher_profile:,
                                      attributes: { category: "attention", observation: "Focused after a break" }).call
    expect(observation).to be_persisted
    expect(observation.created_by).to eq(teacher_profile.user)
  end

  it "rejects unrelated teachers and highly sensitive teacher observations" do
    unrelated = create(:teacher_profile, :active, :verified)
    denied = described_class.new(actor: unrelated.user, student_profile: student, teacher_profile: unrelated,
                                 attributes: { category: "attention", observation: "No access" }).call
    sensitive = described_class.new(actor: teacher_profile.user, student_profile: student, teacher_profile:,
                                    attributes: { category: "other", observation: "Restricted",
                                                  sensitivity: "highly_sensitive" }).call
    expect(denied.errors.details[:base]).to include(error: :forbidden)
    expect(sensitive.errors.details[:base]).to include(error: :forbidden)
  end

  it "keeps sensitive teacher observations internal" do
    observation = described_class.new(actor: teacher_profile.user, student_profile: student, teacher_profile:,
                                      attributes: { category: "behaviour", observation: "Needs support",
                                                    sensitivity: "sensitive", visibility: "guardian_safe" }).call
    expect(observation.errors.details[:base]).to include(error: :forbidden)
  end

  it "accepts a matching lesson and rejects teacher or student mismatches" do
    lesson = create(:scheduled_lesson, :scheduled, teacher_profile:)
    participant = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
    valid = described_class.new(actor: teacher_profile.user, student_profile: participant.student_profile,
                                teacher_profile:, attributes: { category: "tajweed", observation: "Clearer madd",
                                                                scheduled_lesson_id: lesson.id }).call
    other_student = create(:student_profile, assigned_teacher_profile: teacher_profile)
    student_mismatch = described_class.new(actor: teacher_profile.user, student_profile: other_student,
                                           teacher_profile:,
                                           attributes: { category: "tajweed", observation: "Mismatch",
                                                         scheduled_lesson_id: lesson.id }).call
    other_teacher = create(:teacher_profile, :active, :verified)
    teacher_mismatch = described_class.new(actor: other_teacher.user, student_profile: participant.student_profile,
                                           teacher_profile: other_teacher,
                                           attributes: { category: "tajweed", observation: "Mismatch",
                                                         scheduled_lesson_id: lesson.id }).call
    expect(valid).to be_persisted
    expect(student_mismatch.errors[:scheduled_lesson]).to be_present
    expect(teacher_mismatch.errors).to be_present
  end

  it "allows an administrator to record an observation attributed to a teacher" do
    admin = create(:user, :admin)
    observation = described_class.new(actor: admin, student_profile: student, teacher_profile:,
                                      attributes: { category: "other", observation: "Administrator entry",
                                                    source: "admin_entry", sensitivity: "highly_sensitive" }).call
    expect(observation).to be_persisted
    expect(observation.created_by).to eq(admin)
  end

  it "does not accept a caller-supplied administrative source from a teacher" do
    observation = described_class.new(actor: teacher_profile.user, student_profile: student, teacher_profile:,
                                      attributes: { category: "other", observation: "Teacher entry",
                                                    source: "admin_entry" }).call
    expect(observation.source).to eq("teacher_entry")
  end
end
# rubocop:enable RSpec/ExampleLength
