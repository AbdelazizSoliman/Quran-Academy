require "rails_helper"

RSpec.describe "Teacher scheduling services" do
  let(:admin) { create(:user, :admin) }

  it "calculates recurring availability and exception blocking" do
    teacher = create(:teacher_profile, :active, :complete, :verified)
    create(:teacher_availability, teacher_profile: teacher, weekday: 2.days.from_now.strftime("%A").downcase,
                                  starts_at_local: "00:00", ends_at_local: "23:59")
    lesson = build(:scheduled_lesson, teacher_profile: teacher)
    result = TeacherScheduling::AvailabilityCheck.call(teacher_profile: teacher, starts_at: lesson.starts_at,
                                                       ends_at: lesson.ends_at)
    expect(result).to respond_to(:available?)
  end

  it "prevents overlapping teacher lessons" do
    first = create(:scheduled_lesson, :scheduled)
    second = build(:scheduled_lesson, teacher_profile: first.teacher_profile, course_offering: first.course_offering,
                                      starts_at: first.starts_at + 15.minutes, ends_at: first.ends_at + 15.minutes)
    result = Scheduling::ConflictCheck.call(lesson: second, starts_at: second.starts_at, ends_at: second.ends_at,
                                            teacher_profile: second.teacher_profile, enrollment_ids: [])
    expect(result.conflicts?).to be(true)
  end

  it "prevents double-booking an enrollment-backed student across different lessons" do
    first = create(:scheduled_lesson, :scheduled)
    participation = create(:scheduled_lesson_enrollment, scheduled_lesson: first)
    second = build(:scheduled_lesson, teacher_profile: create(:teacher_profile, :active, :verified),
                                      starts_at: first.starts_at + 15.minutes, ends_at: first.ends_at + 15.minutes)

    result = Scheduling::ConflictCheck.call(lesson: second, starts_at: second.starts_at, ends_at: second.ends_at,
                                            teacher_profile: second.teacher_profile,
                                            enrollment_ids: [participation.enrollment_id])

    expect(result.conflicts?).to be(true)
    expect(result.student_conflicts).to contain_exactly(first)
  end

  it "prevents double-booking a direct-participation student across different lessons" do
    profile = create(:student_profile, :complete)
    first = create(:scheduled_lesson, :scheduled, course_offering: nil)
    create(:scheduled_lesson_enrollment, scheduled_lesson: first, enrollment: nil, student_profile: profile)
    second = build(:scheduled_lesson, teacher_profile: create(:teacher_profile, :active, :verified),
                                      starts_at: first.starts_at + 15.minutes, ends_at: first.ends_at + 15.minutes)

    result = Scheduling::ConflictCheck.call(lesson: second, starts_at: second.starts_at, ends_at: second.ends_at,
                                            teacher_profile: second.teacher_profile, enrollment_ids: [],
                                            student_profile_ids: [profile.id])

    expect(result.conflicts?).to be(true)
    expect(result.student_conflicts).to contain_exactly(first)
  end

  it "allows an unrelated student to be scheduled at the same time as a direct participant" do
    profile = create(:student_profile, :complete)
    other_profile = create(:student_profile, :complete)
    first = create(:scheduled_lesson, :scheduled, course_offering: nil)
    create(:scheduled_lesson_enrollment, scheduled_lesson: first, enrollment: nil, student_profile: profile)
    second = build(:scheduled_lesson, teacher_profile: create(:teacher_profile, :active, :verified),
                                      starts_at: first.starts_at + 15.minutes, ends_at: first.ends_at + 15.minutes)

    result = Scheduling::ConflictCheck.call(lesson: second, starts_at: second.starts_at, ends_at: second.ends_at,
                                            teacher_profile: second.teacher_profile, enrollment_ids: [],
                                            student_profile_ids: [other_profile.id])

    expect(result.conflicts?).to be(false)
  end

  it "records explicit scheduling lifecycle events" do
    lesson = create(:scheduled_lesson)
    result = Admin::ScheduledLessons::Transition.new(actor: admin, lesson:, action: :cancel,
                                                     cancellation_reason: "Academy closure").call
    expect(result).to be_cancelled
    expect(result.events.last.event_type).to eq("cancelled")
  end

  it "reschedules times without reassigning the immutable academy time zone" do
    lesson = create(:scheduled_lesson, :scheduled, academy_time_zone: "Cairo")
    new_start = 3.days.from_now.change(hour: 12)
    new_end = new_start + 1.hour

    result = Admin::ScheduledLessons::Reschedule.new(
      actor: admin, lesson:, starts_at: new_start.strftime("%Y-%m-%dT%H:%M"),
      ends_at: new_end.strftime("%Y-%m-%dT%H:%M")
    ).call

    expect(result.errors).to be_empty
    expect(result.reload.academy_time_zone).to eq("Cairo")
    expect(result.starts_at).to eq(new_start)
    expect(result.events.where(event_type: "rescheduled")).to exist
  end
end
