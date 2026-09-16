require "rails_helper"

RSpec.describe StudentLearningProfiles::Access do
  let(:teacher_profile) { create(:teacher_profile, :active, :verified) }
  let(:access) { described_class.new(teacher_profile.user) }

  it "grants access through direct assignment and denies unrelated students" do
    assigned = create(:student_profile, assigned_teacher_profile: teacher_profile)
    unrelated = create(:student_profile)
    expect(access.student_scope).to include(assigned)
    expect(access.student_scope).not_to include(unrelated)
  end

  it "grants access through approved, active, and paused enrollments taught by the teacher" do
    offering = create(:course_offering, :open)
    create(:course_offering_teacher, course_offering: offering, teacher_profile:)
    approved = create(:enrollment, :approved, course_offering: offering).student_profile
    active = create(:enrollment, :active, course_offering: offering).student_profile
    paused_enrollment = create(:enrollment, :active, course_offering: offering)
    paused_enrollment.update!(status: "paused", paused_on: Date.current)
    historical = create(:enrollment, :completed, course_offering: offering).student_profile
    expect(access.student_scope).to include(approved, active, paused_enrollment.student_profile)
    expect(access.student_scope).not_to include(historical)
  end

  it "grants access through operational lessons but not historical lessons alone" do
    current_lesson = create(:scheduled_lesson, :scheduled, teacher_profile:)
    current = create(:scheduled_lesson_enrollment, scheduled_lesson: current_lesson).student_profile
    old_lesson = create(:scheduled_lesson, teacher_profile:, status: "completed", started_at: 2.days.ago,
                                           ended_at: 2.days.ago + 1.hour, completed_at: 2.days.ago + 1.hour)
    historical = create(:scheduled_lesson_enrollment, scheduled_lesson: old_lesson).student_profile
    expect(access.student_scope).to include(current)
    expect(access.student_scope).not_to include(historical)
  end

  it "allows active administrators globally and denies students" do
    student = create(:student_profile)
    expect(described_class.new(create(:user, :admin)).student_scope).to include(student)
    expect(described_class.new(student.user).student_scope).to be_empty
  end

  it "denies inactive teachers" do
    assigned = create(:student_profile, assigned_teacher_profile: teacher_profile)
    teacher_profile.user.update!(status: "suspended")
    expect(access.student_scope).not_to include(assigned)
  end

  it "does not grant access for removed or non-operational lesson participation" do
    lesson = create(:scheduled_lesson, :scheduled, teacher_profile:)
    removed = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
    removed.update!(participation_status: "removed")
    draft_lesson = create(:scheduled_lesson, teacher_profile:)
    draft_student = create(:scheduled_lesson_enrollment, scheduled_lesson: draft_lesson).student_profile
    expect(access.student_scope).not_to include(removed.student_profile, draft_student)
  end
end
