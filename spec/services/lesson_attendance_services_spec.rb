require "rails_helper"

RSpec.describe "Lesson attendance services" do
  let(:admin) { create(:user, :admin) }
  let(:lesson) { create(:scheduled_lesson, :scheduled, starts_at: 5.minutes.from_now, ends_at: 65.minutes.from_now) }
  let(:teacher) { lesson.teacher_profile.user }
  let!(:participant) { create(:scheduled_lesson_enrollment, scheduled_lesson: lesson) }

  it "checks in the assigned teacher and is idempotent" do
    result = LessonOperations::CheckIn.new(actor: teacher, lesson:).call
    expect(result.teacher_attendance_status).to eq("on_time")
    expect { LessonOperations::CheckIn.new(actor: teacher, lesson: result).call }
      .not_to change(ScheduledLessonEvent, :count)
  end

  it "allows teacher check-in at the inclusive 15-minute opening boundary" do
    AcademySetting.current.update!(teacher_check_in_opens_minutes_before: 15,
                                   teacher_check_in_closes_minutes_after: 30)

    result = LessonOperations::CheckIn.new(actor: teacher, lesson:,
                                           occurred_at: lesson.starts_at - 15.minutes).call

    expect(result.errors).to be_empty
    expect(result.teacher_checked_in_at).to eq(lesson.starts_at - 15.minutes)
  end

  it "requires a reason for administrator check-in override" do
    result = LessonOperations::CheckIn.new(actor: admin, lesson:, override: true).call
    expect(result.errors).to be_present
    result.errors.clear
    LessonOperations::CheckIn.new(actor: admin, lesson: result, override: true, reason: "Teacher called").call
    expect(result.reload.teacher_attendance_status).to eq("administrator_override")
  end

  it "opens attendance and initializes expected participants idempotently" do
    LessonOperations::CheckIn.new(actor: teacher, lesson:).call
    LessonOperations::Start.new(actor: teacher, lesson:).call
    expect(lesson.reload).to be_in_progress
    expect(lesson.attendance_status).to eq("open")
    expect { LessonAttendances::Initialize.new(actor: teacher, lesson:).call }.not_to change(LessonAttendance, :count)
  end

  it "initializes a participant added after attendance opens" do
    lesson.update!(attendance_status: "open", status: "in_progress", started_at: Time.current)
    LessonAttendances::Initialize.new(actor: admin, lesson:).call
    other = create(:enrollment, :approved, course_offering: lesson.course_offering)
    expect do
      Admin::ScheduledLessons::Participants::Add.new(actor: admin, lesson:, enrollment: other).call
    end.to change(LessonAttendance, :count).by(1)
  end

  it "records on-time and corrected late arrival" do
    attendance = opened_attendance
    LessonAttendances::RecordArrival.new(actor: teacher, attendance:, occurred_at: lesson.starts_at + 2.minutes).call
    expect(attendance).to be_present
    LessonAttendances::RecordArrival.new(actor: admin, attendance:, occurred_at: lesson.starts_at + 8.minutes,
                                         adjustment_reason: "Corrected from register").call
    expect(attendance).to be_late
    expect(attendance.minutes_late).to eq(8)
  end

  it "prevents negative lateness for early arrivals" do
    attendance = opened_attendance
    LessonAttendances::RecordArrival.new(actor: teacher, attendance:, occurred_at: lesson.starts_at - 2.minutes).call
    expect(attendance.minutes_late).to be_zero
  end

  it "requires absence threshold or administrator override reason" do
    attendance = opened_attendance
    expect(LessonAttendances::MarkAbsent.new(actor: teacher, attendance:).call.errors).to be_present
    attendance.errors.clear
    LessonAttendances::MarkAbsent.new(actor: admin, attendance:, override: true, reason: "Confirmed").call
    expect(attendance).to be_absent
  end

  it "automatically starts overdue lessons and marks students who did not join absent" do
    lesson.update!(starts_at: 20.minutes.ago, ends_at: 40.minutes.from_now)
    AcademySetting.current.update!(absence_after_minutes: 15)

    LessonAttendances::AutomaticSweep.new(actor: admin).call

    expect(lesson.reload).to be_in_progress
    expect(participant.reload.lesson_attendance).to be_absent
  end

  it "preserves automatic presence when a student joined before the absence sweep" do
    lesson.update!(starts_at: 20.minutes.ago, ends_at: 40.minutes.from_now)
    attendance = LessonAttendances::Join.new(actor: participant.student_profile.user, lesson:,
                                             participation: participant, occurred_at: lesson.starts_at).call

    LessonAttendances::AutomaticSweep.new(actor: admin).call

    expect(attendance.reload).to be_present
  end

  it "requires excuse reason and supports left-early departure" do
    attendance = opened_attendance
    expect(LessonAttendances::Excuse.new(actor: teacher, attendance:, reason: nil).call.errors).to be_present
    attendance.errors.clear
    LessonAttendances::RecordArrival.new(actor: teacher, attendance:, occurred_at: lesson.starts_at).call
    LessonAttendances::RecordDeparture.new(actor: teacher, attendance:,
                                           occurred_at: lesson.ends_at - 10.minutes).call
    expect(attendance).to be_left_early
  end

  it "requires unresolved confirmation and locks on completion" do
    opened_attendance
    expect(LessonOperations::Complete.new(actor: teacher, lesson:).call.errors).to be_present
    lesson.errors.clear
    LessonOperations::Complete.new(actor: teacher, lesson:, options: { mark_unresolved_absent: true }).call
    expect(lesson.reload).to be_completed
    expect(lesson).to be_attendance_locked
    expect(lesson.lesson_attendances.first).to be_absent
  end

  it "allows only administrator reopening and audits adjustment" do
    lesson.update!(attendance_status: "locked", status: "completed", started_at: 1.hour.ago,
                   ended_at: Time.current, completed_at: Time.current)
    attendance = create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: participant,
                                            status: "absent")
    expect(LessonOperations::ReopenAttendance.new(actor: teacher, lesson:, reason: "No").call.errors).to be_present
    lesson.errors.clear
    LessonOperations::ReopenAttendance.new(actor: admin, lesson:, reason: "Evidence received").call
    expect do
      LessonAttendances::Adjust.new(actor: admin, attendance:,
                                    attributes: { status: "present", reason: "Corrected" }).call
    end.to change(LessonAttendanceEvent, :count).by(1)
  end

  private

  def opened_attendance
    lesson.update!(attendance_status: "open", status: "in_progress", started_at: Time.current)
    LessonAttendances::Initialize.new(actor: teacher, lesson:).call.first
  end
end
