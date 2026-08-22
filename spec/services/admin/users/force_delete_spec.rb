require "rails_helper"

RSpec.describe Admin::Users::ForceDelete do
  let(:privileged_admin) { create(:user, :admin) }
  let(:target) { create(:user, :student) }

  it "hard deletes a user along with notifications, attempts, events, invitations, and profile" do
    notification = create(:notification, recipient_user: target, actor: privileged_admin)
    create(:notification_attempt, notification:)
    create(:notification_event, notification:)
    invitation = create(:account_invitation, user: target, created_by: privileged_admin)
    create(:account_invitation_event, account_invitation: invitation)
    profile = create(:student_profile, user: target)
    create(:student_profile_event, student_profile: profile, actor: privileged_admin)

    expect do
      described_class.new(actor: privileged_admin, user: target).call
    end.to change(User, :count).by(-1)

    expect(User.exists?(target.id)).to be(false)
    expect(Notification.exists?(notification.id)).to be(false)
    expect(NotificationAttempt.exists?(notification_id: notification.id)).to be(false)
    expect(NotificationEvent.exists?(notification_id: notification.id)).to be(false)
    expect(AccountInvitation.exists?(invitation.id)).to be(false)
    expect(StudentProfile.exists?(profile.id)).to be(false)
  end

  it "refuses to delete when the actor is not an administrator" do
    other_admin = create(:user, :staff)
    expect do
      described_class.new(actor: other_admin, user: target).call
    end.to raise_error(Admin::Users::Operation::Forbidden)
    expect(User.exists?(target.id)).to be(true)
  end

  it "permanently deletes a student even when they have recurring scheduling records" do
    profile = create(:student_profile, user: target, fee_plan: create(:fee_plan))
    schedule = create(:enrollment_lesson_schedule, enrollment: nil, student_profile: profile,
                                                   created_by: privileged_admin, updated_by: privileged_admin)
    slot = create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule)
    lesson = create(:scheduled_lesson, course_offering: nil,
                                       enrollment_lesson_schedule_slot: slot,
                                       recurrence_date: Date.current)
    create(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment: nil, student_profile: profile)

    described_class.new(actor: privileged_admin, user: target).call

    expect(User.exists?(target.id)).to be(false)
    expect(EnrollmentLessonSchedule.exists?(schedule.id)).to be(false)
    expect(ScheduledLesson.exists?(lesson.id)).to be(false)
  end

  it "cascades through a teacher's full operational history, deleting only what belongs to them" do
    teacher_user = create(:user, :teacher)
    teacher_profile = create(:teacher_profile, :active, :verified, user: teacher_user)
    create(:teacher_profile_event, teacher_profile:, actor: privileged_admin)

    availability = create(:teacher_availability, teacher_profile:, created_by: privileged_admin)
    availability_event = TeacherAvailabilityEvent.create!(
      teacher_availability: availability, actor: privileged_admin, event_type: "created"
    )

    scheduled_lesson = create(:scheduled_lesson, teacher_profile:, created_by: privileged_admin)
    scheduled_lesson_event = ScheduledLessonEvent.create!(
      scheduled_lesson:, actor: privileged_admin, event_type: "created"
    )

    other_student = create(:student_profile, :complete)
    enrollment = create(:enrollment, :approved, student_profile: other_student,
                                                 course_offering: scheduled_lesson.course_offering)
    scheduled_lesson_enrollment = create(:scheduled_lesson_enrollment, scheduled_lesson:, enrollment:)
    attendance = create(:lesson_attendance, scheduled_lesson_enrollment:)

    lesson_report = create(:lesson_report, scheduled_lesson:, teacher_profile:, created_by: privileged_admin)
    create(:lesson_report_event, lesson_report:, actor: privileged_admin)

    payroll = create(:teacher_payroll, teacher_profile:, created_by: privileged_admin)
    create(:teacher_payroll_event, teacher_payroll: payroll, actor: privileged_admin)

    assigned_student = create(:student_profile, :complete, assigned_teacher_profile: teacher_profile)

    expect do
      described_class.new(actor: privileged_admin, user: teacher_user).call
    end.to change(User, :count).by(-1)

    expect(TeacherProfile.exists?(teacher_profile.id)).to be(false)
    expect(TeacherAvailability.exists?(availability.id)).to be(false)
    expect(TeacherAvailabilityEvent.exists?(availability_event.id)).to be(false)
    expect(ScheduledLesson.exists?(scheduled_lesson.id)).to be(false)
    expect(ScheduledLessonEvent.exists?(scheduled_lesson_event.id)).to be(false)
    expect(ScheduledLessonEnrollment.exists?(scheduled_lesson_enrollment.id)).to be(false)
    expect(LessonAttendance.exists?(attendance.id)).to be(false)
    expect(LessonReport.exists?(lesson_report.id)).to be(false)
    expect(TeacherPayroll.exists?(payroll.id)).to be(false)

    expect(StudentProfile.exists?(other_student.id)).to be(true)
    expect(Enrollment.exists?(enrollment.id)).to be(true)

    expect(assigned_student.reload.assigned_teacher_profile_id).to be_nil
  end
end
