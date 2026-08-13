require "rails_helper"

RSpec.describe EnrollmentLessonSchedule do
  it "belongs to an enrollment and teacher and supports multiple ordered slots" do
    schedule = create(:enrollment_lesson_schedule)
    create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule, weekday: "sunday",
                                             starts_at_local: "18:00", position: 1)
    create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule, weekday: "tuesday",
                                             starts_at_local: "19:30", position: 2)

    expect(schedule.enrollment).to be_present
    expect(schedule.teacher_profile).to be_present
    expect(schedule.reload.weekly_lesson_count).to eq(2)
  end

  it "validates timezone, nullable end date, and date order" do
    expect(build(:enrollment_lesson_schedule, ends_on: nil)).to be_valid
    expect(build(:enrollment_lesson_schedule, time_zone: "Not/AZone")).not_to be_valid
    expect(build(:enrollment_lesson_schedule, starts_on: Date.current,
                                              ends_on: Date.current - 1.day)).not_to be_valid
  end

  it "supports superseded and cancelled lifecycle states" do
    expect(build(:enrollment_lesson_schedule, status: "superseded")).to be_valid
    expect(build(:enrollment_lesson_schedule, status: "cancelled")).to be_valid
  end

  it "supports a direct student_profile schedule with no enrollment" do
    profile = create(:student_profile, :complete)
    schedule = create(:enrollment_lesson_schedule, enrollment: nil, student_profile: profile)

    expect(schedule.enrollment).to be_nil
    expect(schedule.student_profile).to eq(profile)
  end

  it "falls back to the enrollment's student_profile when there is no direct student_profile" do
    schedule = create(:enrollment_lesson_schedule)

    expect(schedule.student_profile).to eq(schedule.enrollment.student_profile)
  end

  it "requires exactly one of enrollment or student_profile" do
    neither = build(:enrollment_lesson_schedule, enrollment: nil, student_profile: nil)
    both = build(:enrollment_lesson_schedule, student_profile: create(:student_profile, :complete))

    expect(neither).not_to be_valid
    expect(both).not_to be_valid
  end

  it "validates weekdays, times, and duplicate weekday/time slots" do
    schedule = create(:enrollment_lesson_schedule)
    create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule, weekday: "sunday",
                                             starts_at_local: "18:00")
    duplicate = build(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule,
                                                        weekday: "sunday", starts_at_local: "18:00")
    invalid_day = build(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule,
                                                          weekday: "funday", starts_at_local: "18:00")
    missing_time = build(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule,
                                                           starts_at_local: nil)

    expect(duplicate).not_to be_valid
    expect(invalid_day).not_to be_valid
    expect(missing_time).not_to be_valid
  end
end
