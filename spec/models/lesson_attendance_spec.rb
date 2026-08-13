require "rails_helper"

RSpec.describe LessonAttendance do
  it "generates immutable public identity and canonical ownership" do
    attendance = create(:lesson_attendance)
    expect(attendance.public_id).to match(/\AATT-[A-Z0-9]{10}\z/)
    expect(attendance.student_profile).to eq(attendance.enrollment.student_profile)
    expect { attendance.update!(scheduled_lesson_id: create(:scheduled_lesson).id) }
      .to raise_error(ActiveRecord::ReadonlyAttributeError)
  end

  it "resolves the correct student for a direct (enrollment-less) participation" do
    profile = create(:student_profile, :complete)
    lesson = create(:scheduled_lesson, course_offering: nil)
    participation = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment: nil,
                                                         student_profile: profile)
    attendance = create(:lesson_attendance, scheduled_lesson_enrollment: participation, scheduled_lesson: lesson)

    expect(attendance.student_profile).to eq(profile)
  end

  it "allows only controlled statuses and nonnegative lateness" do
    expect(build(:lesson_attendance, status: "unknown", minutes_late: -1)).not_to be_valid
  end

  it "requires an excuse reason" do
    expect(build(:lesson_attendance, status: "excused_absence", excuse_reason: nil)).not_to be_valid
  end

  it "rejects departure before arrival and departure for absence" do
    attendance = build(:lesson_attendance, status: "absent", arrival_at: Time.current,
                                           departure_at: 1.minute.ago)
    expect(attendance).not_to be_valid
  end

  it "restricts destruction when audit history exists" do
    attendance = create(:lesson_attendance)
    create(:lesson_attendance_event, lesson_attendance: attendance)
    expect { attendance.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end
end
