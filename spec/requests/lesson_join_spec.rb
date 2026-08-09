require "rails_helper"

RSpec.describe "Role-aware lesson join" do
  include ActiveSupport::Testing::TimeHelpers

  describe "student join" do
    it "records arrival for an expected student and redirects to the normalized meeting URL" do
      lesson, participation = student_lesson(
        online_meeting_url: "https://bad.example.testhttps//meet.example.test/room?key=safe"
      )
      sign_in participation.enrollment.student_profile.user

      travel_to(lesson.starts_at) { get join_student_schedule_path(lesson) }

      attendance = participation.reload.lesson_attendance
      expect(response).to redirect_to("https://meet.example.test/room?key=safe")
      expect(attendance.arrival_at).to be_within(1.second).of(lesson.starts_at)
      expect(attendance).to be_present
      expect(attendance.events.pluck(:event_type)).to eq(%w[initialized arrival_recorded])
    end

    it "is idempotent across repeated joins" do
      lesson, participation = student_lesson
      sign_in participation.enrollment.student_profile.user
      travel_to(lesson.starts_at) { get join_student_schedule_path(lesson) }
      attendance = participation.reload.lesson_attendance

      expect do
        travel_to(lesson.starts_at + 1.minute) { get join_student_schedule_path(lesson) }
      end.not_to change(attendance.events, :count)
      expect(attendance.reload.arrival_at).to be_within(1.second).of(lesson.starts_at)
    end

    it "does not allow another student to join or record presence" do
      lesson, participation = student_lesson
      sign_in create(:student_profile, :complete).user

      expect { get join_student_schedule_path(lesson) }.not_to change(LessonAttendance, :count)
      expect(response).to have_http_status(:not_found)
      expect(participation.reload.lesson_attendance).to be_nil
    end

    it "fails safely without recording arrival when the URL is missing or invalid" do
      lesson, participation = student_lesson
      student_user = participation.enrollment.student_profile.user
      sign_in student_user

      [nil, "javascript:alert(1)"].each do |value|
        lesson.update_column(:online_meeting_url, value) # rubocop:disable Rails/SkipsModelValidations -- invalid state
        expect { get join_student_schedule_path(lesson) }.not_to change(LessonAttendance, :count)
        expect(response).to redirect_to(student_schedule_path(lesson))
        expect(flash[:alert]).to eq(I18n.t("scheduling.join.invalid_url", locale: student_user.preferred_locale))
      end
    end
  end

  describe "teacher join" do
    it "checks in the assigned teacher and redirects to the meeting" do
      lesson = teacher_lesson
      sign_in lesson.teacher_profile.user

      travel_to(lesson.starts_at) { get join_teacher_schedule_path(lesson) }

      expect(response).to redirect_to(lesson.online_meeting_join_url)
      expect(lesson.reload.teacher_checked_in_at).to be_within(1.second).of(lesson.starts_at)
      expect(lesson.teacher_attendance_status).to eq("on_time")
      expect(lesson.events.where(event_type: "teacher_checked_in").count).to eq(1)
    end

    it "is idempotent across repeated joins" do
      lesson = teacher_lesson
      sign_in lesson.teacher_profile.user
      travel_to(lesson.starts_at) { get join_teacher_schedule_path(lesson) }

      expect do
        travel_to(lesson.starts_at + 1.minute) { get join_teacher_schedule_path(lesson) }
      end.not_to change(lesson.events.where(event_type: "teacher_checked_in"), :count)
      expect(lesson.reload.teacher_checked_in_at).to be_within(1.second).of(lesson.starts_at)
    end

    it "denies a teacher who is not assigned to the lesson" do
      lesson = teacher_lesson
      other_teacher = create(:teacher_profile, :active, :verified)
      sign_in other_teacher.user

      get join_teacher_schedule_path(lesson)

      expect(response).to have_http_status(:not_found)
      expect(lesson.reload.teacher_checked_in_at).to be_nil
    end

    it "fails safely without checking in when the URL is missing or invalid" do
      lesson = teacher_lesson
      teacher_user = lesson.teacher_profile.user
      sign_in teacher_user

      [nil, "javascript:alert(1)"].each do |value|
        lesson.update_column(:online_meeting_url, value) # rubocop:disable Rails/SkipsModelValidations -- invalid state
        get join_teacher_schedule_path(lesson)
        expect(response).to redirect_to(teacher_schedule_path(lesson))
        expect(flash[:alert]).to eq(I18n.t("scheduling.join.invalid_url", locale: teacher_user.preferred_locale))
        expect(lesson.reload.teacher_checked_in_at).to be_nil
      end
    end
  end

  private

  def student_lesson(online_meeting_url: "https://meet.example.test/room")
    lesson = create(:scheduled_lesson, :scheduled, starts_at: 5.minutes.from_now,
                                                   ends_at: 50.minutes.from_now, online_meeting_url:)
    enrollment = create(:enrollment, :active, course_offering: lesson.course_offering)
    participation = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment:)
    [lesson, participation]
  end

  def teacher_lesson
    create(:scheduled_lesson, :scheduled, starts_at: 5.minutes.from_now, ends_at: 50.minutes.from_now)
  end
end
