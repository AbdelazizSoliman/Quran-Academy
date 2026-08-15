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

  it "treats blank working hours on a selected work day as available at any time that day" do
    teacher = create(:teacher_profile, :active, :verified, work_days: %w[thursday], work_start_time: nil,
                                                           work_end_time: nil)
    starts_at = Time.find_zone!("Cairo").local(2026, 8, 13, 23, 0)

    result = TeacherScheduling::AvailabilityCheck.call(teacher_profile: teacher, starts_at:,
                                                       ends_at: starts_at + 30.minutes)

    expect(result.available?).to be(true)
  end

  it "treats an unselected work day as unavailable" do
    teacher = create(:teacher_profile, :active, :verified, work_days: %w[thursday], work_start_time: "09:00",
                                                           work_end_time: "17:00")
    starts_at = Time.find_zone!("Cairo").local(2026, 8, 14, 10, 0)

    result = TeacherScheduling::AvailabilityCheck.call(teacher_profile: teacher, starts_at:,
                                                       ends_at: starts_at + 30.minutes)

    expect(result.available?).to be(false)
  end

  it "restricts a selected work day with configured hours to inside that range and blocks outside it" do
    teacher = create(:teacher_profile, :active, :verified, work_days: %w[thursday], work_start_time: "09:00",
                                                           work_end_time: "17:00")
    inside = Time.find_zone!("Cairo").local(2026, 8, 13, 10, 0)
    outside = Time.find_zone!("Cairo").local(2026, 8, 13, 20, 0)

    inside_result = TeacherScheduling::AvailabilityCheck.call(teacher_profile: teacher, starts_at: inside,
                                                              ends_at: inside + 30.minutes)
    outside_result = TeacherScheduling::AvailabilityCheck.call(teacher_profile: teacher, starts_at: outside,
                                                               ends_at: outside + 30.minutes)

    expect(inside_result.available?).to be(true)
    expect(outside_result.available?).to be(false)
  end

  it "interprets profile working hours in the teacher timezone, independent of academy timezone" do
    AcademySetting.current.update!(default_time_zone: "Cairo")
    teacher = create(:teacher_profile, :active, :verified,
                     user: create(:user, :teacher, time_zone: "Riyadh"),
                     work_days: %w[thursday], work_start_time: "09:00", work_end_time: "17:00")
    inside = Time.find_zone!("Riyadh").local(2026, 1, 8, 9, 30)
    outside = Time.find_zone!("Riyadh").local(2026, 1, 8, 8, 30)

    expect(TeacherScheduling::AvailabilityCheck.call(teacher_profile: teacher, starts_at: inside,
                                                      ends_at: inside + 30.minutes)).to be_available
    expect(TeacherScheduling::AvailabilityCheck.call(teacher_profile: teacher, starts_at: outside,
                                                      ends_at: outside + 30.minutes)).not_to be_available
  end

  it "still blocks an overlapping lesson for a teacher who is all-day available via work_days" do
    teacher = create(:teacher_profile, :active, :verified, work_days: %w[thursday], work_start_time: nil,
                                                           work_end_time: nil)
    starts_at = Time.find_zone!("Cairo").local(2026, 8, 13, 18, 0)
    create(:scheduled_lesson, :scheduled, teacher_profile: teacher, starts_at:, ends_at: starts_at + 45.minutes)
    overlapping = build(:scheduled_lesson, teacher_profile: teacher, starts_at: starts_at + 15.minutes,
                                           ends_at: starts_at + 60.minutes)

    availability = TeacherScheduling::AvailabilityCheck.call(teacher_profile: teacher,
                                                             starts_at: overlapping.starts_at,
                                                             ends_at: overlapping.ends_at)
    conflict = Scheduling::ConflictCheck.call(lesson: overlapping, starts_at: overlapping.starts_at,
                                              ends_at: overlapping.ends_at, teacher_profile: teacher,
                                              enrollment_ids: [])

    expect(availability.available?).to be(true)
    expect(conflict.conflicts?).to be(true)
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

  it "schedules a draft lesson for a work_days all-day teacher but blocks it when another lesson overlaps" do
    teacher = create(:teacher_profile, :active, :verified, online_meeting_url: "https://meet.example.test/teacher",
                                                           work_days: %w[thursday], work_start_time: nil,
                                                           work_end_time: nil)
    starts_at = Time.find_zone!("Cairo").local(2026, 8, 13, 18, 0)
    draft = create(:scheduled_lesson, teacher_profile: teacher, starts_at:, ends_at: starts_at + 45.minutes)

    scheduled = Admin::ScheduledLessons::Transition.new(actor: admin, lesson: draft, action: :schedule).call
    expect(scheduled).to be_scheduled

    overlapping_draft = create(:scheduled_lesson, teacher_profile: teacher, starts_at: starts_at + 15.minutes,
                                                  ends_at: starts_at + 60.minutes)
    blocked = Admin::ScheduledLessons::Transition.new(actor: admin, lesson: overlapping_draft, action: :schedule).call

    expect(blocked).not_to be_scheduled
    expect(blocked.errors.of_kind?(:base, :schedule_conflict)).to be true
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
