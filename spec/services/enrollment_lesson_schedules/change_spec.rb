require "rails_helper"

RSpec.describe "Recurring lesson one-off and version changes" do
  let(:admin) { create(:user, :admin) }
  let(:teacher) do
    create(:teacher_profile, :active, :verified, online_meeting_url: "https://meet.example.test/default")
  end
  let(:enrollment) { create(:enrollment, :approved) }
  let(:schedule) do
    create(:enrollment_lesson_schedule, enrollment:, teacher_profile: teacher,
                                        starts_on: Date.new(2026, 8, 1), time_zone: "Cairo",
                                        created_by: admin, updated_by: admin)
  end
  let!(:slot) do
    create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule,
                                             weekday: "tuesday", starts_at_local: "18:00")
  end

  before do
    create(:teacher_availability, teacher_profile: teacher, weekday: "tuesday",
                                  starts_at_local: "17:00", ends_at_local: "21:00",
                                  effective_from: Date.new(2026, 8, 1))
    create(:teacher_availability, teacher_profile: teacher, weekday: "wednesday",
                                  starts_at_local: "17:00", ends_at_local: "21:00",
                                  effective_from: Date.new(2026, 8, 1))
  end

  it "does not recreate a generated occurrence after one-off rescheduling" do
    lesson = generate(Date.new(2026, 8, 18))
    original_identity = lesson.attributes.values_at("enrollment_lesson_schedule_slot_id", "recurrence_date")

    Admin::ScheduledLessons::Reschedule.new(
      actor: admin, lesson:, starts_at: lesson.starts_at + 1.day + 1.hour, ends_at: lesson.ends_at + 1.day + 1.hour
    ).call

    expect(lesson.reload.attributes.values_at("enrollment_lesson_schedule_slot_id", "recurrence_date"))
      .to eq(original_identity)
    expect { generate(Date.new(2026, 8, 18)) }.not_to change(ScheduledLesson, :count)
  end

  it "does not recreate a cancelled generated occurrence" do
    lesson = generate(Date.new(2026, 8, 18))
    Admin::ScheduledLessons::Transition.new(
      actor: admin, lesson:, action: :cancel, cancellation_reason: "Student away"
    ).call

    expect(lesson.reload).to be_cancelled
    expect { generate(Date.new(2026, 8, 18)) }.not_to change(ScheduledLesson, :count)
  end

  it "supersedes the old version, preserves history, cancels future occurrences, and generates replacements" do
    historical = generate(Date.new(2026, 8, 18))
    future = generate(Date.new(2026, 9, 15))
    historical.update!(status: "completed", completed_at: Time.current)

    replacement = EnrollmentLessonSchedules::Change.new(
      actor: admin, schedule:, effective_on: Date.new(2026, 9, 1),
      attributes: {
        teacher_profile: teacher, lesson_duration_minutes: 45, time_zone: "Cairo", ends_on: nil
      },
      slots: [{ weekday: "wednesday", starts_at_local: "19:00" }]
    ).call

    expect(schedule.reload).to be_superseded
    expect(schedule.ends_on).to eq(Date.new(2026, 8, 31))
    expect(historical.reload).to be_completed
    expect(future.reload).to be_cancelled
    expect(replacement).to be_active
    expect(replacement.slots.pick(:weekday, :starts_at_local).first).to eq("wednesday")
    expect(replacement.slots.first.scheduled_lessons).not_to be_empty
  end

  def generate(date)
    EnrollmentLessonSchedules::GenerateOccurrences.new(
      schedule:, actor: admin, from_date: date, through_date: date
    ).call.generated.first
  end
end
