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

  it "records explicit scheduling lifecycle events" do
    lesson = create(:scheduled_lesson)
    result = Admin::ScheduledLessons::Transition.new(actor: admin, lesson:, action: :cancel,
                                                     cancellation_reason: "Academy closure").call
    expect(result).to be_cancelled
    expect(result.events.last.event_type).to eq("cancelled")
  end
end
