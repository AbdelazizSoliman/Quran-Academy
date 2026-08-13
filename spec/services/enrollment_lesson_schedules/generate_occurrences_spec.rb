require "rails_helper"

RSpec.describe EnrollmentLessonSchedules::GenerateOccurrences do
  let(:admin) { create(:user, :admin) }
  let(:teacher) do
    create(:teacher_profile, :active, :verified, online_meeting_url: "https://meet.example.test/teacher")
  end
  let(:enrollment) { create(:enrollment, :approved) }
  let(:schedule) do
    create(:enrollment_lesson_schedule, enrollment:, teacher_profile: teacher,
                                        starts_on: Date.new(2026, 8, 9), time_zone: "Riyadh",
                                        lesson_duration_minutes: 45, created_by: admin, updated_by: admin)
  end

  before do
    %w[sunday tuesday thursday].each do |weekday|
      create(:teacher_availability, teacher_profile: teacher, weekday:, starts_at_local: "17:00",
                                    ends_at_local: "21:00", time_zone: "Riyadh",
                                    effective_from: Date.new(2026, 8, 1), availability_type: "teaching")
    end
  end

  it "generates multiple weekdays at different local times with duration and participant" do
    sunday = create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule,
                                                      weekday: "sunday", starts_at_local: "18:00")
    tuesday = create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule,
                                                       weekday: "tuesday", starts_at_local: "19:30")

    result = generate(through_date: Date.new(2026, 8, 18))

    expect(result.generated.size).to eq(4)
    expect(sunday.scheduled_lessons.pluck(:recurrence_date)).to eq(
      [Date.new(2026, 8, 9), Date.new(2026, 8, 16)]
    )
    lesson = tuesday.scheduled_lessons.order(:recurrence_date).first
    expect(lesson.starts_at.in_time_zone("Riyadh").strftime("%F %H:%M")).to eq("2026-08-11 19:30")
    expect((lesson.ends_at - lesson.starts_at) / 60).to eq(45)
    expect(lesson).to be_scheduled
    expect(lesson.enrollments).to contain_exactly(enrollment)
    expect(lesson.online_meeting_url).to be_nil
    expect(lesson.effective_online_meeting_url).to eq(teacher.online_meeting_url)
  end

  it "respects an end date and the requested rolling boundary" do
    schedule.update!(ends_on: Date.new(2026, 8, 16))
    create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule,
                                             weekday: "sunday", starts_at_local: "18:00")

    result = generate(through_date: Date.new(2026, 9, 30))

    expect(result.generated.map(&:recurrence_date)).to eq(
      [Date.new(2026, 8, 9), Date.new(2026, 8, 16)]
    )
  end

  it "is idempotent and database uniqueness protects the recurrence identity" do
    slot = create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule,
                                                    weekday: "sunday", starts_at_local: "18:00")
    generate(through_date: Date.new(2026, 8, 9))

    expect { generate(through_date: Date.new(2026, 8, 9)) }.not_to change(ScheduledLesson, :count)
    duplicate = slot.scheduled_lessons.first.dup
    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "persists one visible issue for unavailable dates without duplicate issue noise" do
    slot = create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule,
                                                    weekday: "monday", starts_at_local: "18:00")

    expect do
      expect { generate(through_date: Date.new(2026, 8, 10)) }.not_to change(ScheduledLesson, :count)
    end.to change(EnrollmentLessonGenerationIssue, :count).by(1)
    expect { generate(through_date: Date.new(2026, 8, 10)) }
      .not_to change(EnrollmentLessonGenerationIssue, :count)
    expect(slot.generation_issues.first.reason_code).to be_present
  end

  it "respects availability exceptions, teacher conflicts, and student conflicts" do
    slot = create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule,
                                                    weekday: "sunday", starts_at_local: "18:00")
    create(:teacher_availability_exception, teacher_profile: teacher, exception_date: Date.new(2026, 8, 9),
                                            exception_type: "unavailable")
    generate(through_date: Date.new(2026, 8, 9))
    expect(slot.generation_issues.find_by(recurrence_date: Date.new(2026, 8, 9))).to be_present

    create(:scheduled_lesson, :scheduled, teacher_profile: teacher,
                                          starts_at: Time.find_zone!("Riyadh").local(2026, 8, 16, 18),
                                          ends_at: Time.find_zone!("Riyadh").local(2026, 8, 16, 19))
    generate(from_date: Date.new(2026, 8, 16), through_date: Date.new(2026, 8, 16))
    expect(slot.generation_issues.find_by(recurrence_date: Date.new(2026, 8, 16))).to be_present

    other = create(:scheduled_lesson, :scheduled, course_offering: enrollment.course_offering,
                                                  starts_at: Time.find_zone!("Riyadh").local(2026, 8, 23, 18),
                                                  ends_at: Time.find_zone!("Riyadh").local(2026, 8, 23, 19))
    create(:scheduled_lesson_enrollment, scheduled_lesson: other, enrollment:)
    generate(from_date: Date.new(2026, 8, 23), through_date: Date.new(2026, 8, 23))
    expect(slot.generation_issues.find_by(recurrence_date: Date.new(2026, 8, 23))).to be_present
  end

  def generate(through_date:, from_date: Date.new(2026, 8, 9))
    described_class.new(schedule:, actor: admin, from_date:, through_date:).call
  end

  context "with a direct student_profile schedule and no enrollment" do
    let(:student_profile) { create(:student_profile, :complete) }
    let(:direct_schedule) do
      create(:enrollment_lesson_schedule, enrollment: nil, student_profile:, teacher_profile: teacher,
                                          starts_on: Date.new(2026, 8, 9), time_zone: "Riyadh",
                                          lesson_duration_minutes: 30, created_by: admin, updated_by: admin)
    end

    it "generates real scheduled lessons with the teacher and student attached directly, no course offering" do
      slot = create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: direct_schedule,
                                                      weekday: "sunday", starts_at_local: "18:00")

      result = described_class.new(schedule: direct_schedule, actor: admin, from_date: Date.new(2026, 8, 9),
                                   through_date: Date.new(2026, 8, 9)).call

      expect(result.generated.size).to eq(1)
      lesson = slot.scheduled_lessons.first
      expect(lesson).to be_present
      expect(lesson).to be_scheduled
      expect(lesson.course_offering_id).to be_nil
      expect(lesson.teacher_profile).to eq(teacher)

      participation = lesson.scheduled_lesson_enrollments.sole
      expect(participation.enrollment_id).to be_nil
      expect(participation.student_profile).to eq(student_profile)
    end
  end
end
