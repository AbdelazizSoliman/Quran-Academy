require "rails_helper"

RSpec.describe ScheduledLessonEnrollment do
  it "resolves student_profile through the enrollment when there is no direct student_profile" do
    participation = create(:scheduled_lesson_enrollment)

    expect(participation.student_profile).to eq(participation.enrollment.student_profile)
  end

  it "resolves student_profile directly when there is no enrollment" do
    profile = create(:student_profile, :complete)
    lesson = create(:scheduled_lesson, course_offering: nil)
    participation = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment: nil,
                                                         student_profile: profile)

    expect(participation.enrollment).to be_nil
    expect(participation.student_profile).to eq(profile)
  end

  it "requires exactly one of enrollment or student_profile" do
    lesson = create(:scheduled_lesson)
    neither = build(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment: nil, student_profile: nil)
    both = build(:scheduled_lesson_enrollment, scheduled_lesson: lesson,
                                               student_profile: create(:student_profile, :complete))

    expect(neither).not_to be_valid
    expect(neither.errors.of_kind?(:base, :participant_required)).to be true
    expect(both).not_to be_valid
    expect(both.errors.of_kind?(:base, :participant_conflict)).to be true
  end

  it "only applies the same-offering validation to enrollment-backed participation" do
    profile = create(:student_profile, :complete)
    lesson = create(:scheduled_lesson, course_offering: nil)
    direct = build(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment: nil, student_profile: profile)

    expect(direct).to be_valid
  end

  it "still rejects an enrollment from a different course offering" do
    lesson = create(:scheduled_lesson)
    other_enrollment = create(:enrollment, :approved)
    mismatched = build(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment: other_enrollment)

    expect(mismatched).not_to be_valid
    expect(mismatched.errors.of_kind?(:enrollment, :different_offering)).to be true
  end
end
