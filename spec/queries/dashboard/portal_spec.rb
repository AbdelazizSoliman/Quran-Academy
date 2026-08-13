require "rails_helper"

RSpec.describe "Dashboard portals" do
  def completed_lesson(**attributes)
    create(:scheduled_lesson, status: "completed", started_at: 1.hour.ago, ended_at: Time.current,
                              completed_at: Time.current, attendance_status: "locked", **attributes)
  end

  def reviewed_report_for(lesson, participant)
    report = LessonReports::Initialize.new(actor: lesson.teacher_profile.user, lesson:).call
    entry = report.lesson_student_reports.find_by(scheduled_lesson_enrollment: participant)
    report.update!(status: "reviewed")
    entry.update!(status: "completed")
    entry
  end

  describe Dashboard::StudentPortal do
    it "counts attendance and reports for an enrollment-backed student unchanged" do
      participant = create(:scheduled_lesson_enrollment)
      profile = participant.enrollment.student_profile
      lesson = participant.scheduled_lesson
      lesson.update!(status: "completed", started_at: 1.hour.ago, ended_at: Time.current,
                     completed_at: Time.current, attendance_status: "locked")
      create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: participant,
                                 status: "present")
      reviewed_report_for(lesson, participant)

      result = described_class.new(user: profile.user).call

      expect(result[:attendance][:total]).to eq(1)
      expect(result[:attendance][:attended]).to eq(1)
      expect(result[:reports_count]).to eq(1)
    end

    it "counts attendance and reports for a fee-plan-only direct-participation student" do
      profile = create(:student_profile, :complete)
      lesson = completed_lesson(course_offering: nil)
      participant = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment: nil,
                                                         student_profile: profile)
      create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: participant,
                                 status: "present")
      reviewed_report_for(lesson, participant)

      result = described_class.new(user: profile.user).call

      expect(result[:attendance][:total]).to eq(1)
      expect(result[:attendance][:attended]).to eq(1)
      expect(result[:reports_count]).to eq(1)
      expect(result[:today_lessons] + result[:upcoming_lessons]).to be_an(Array)
    end
  end

  describe Dashboard::GuardianPortal do
    let(:guardian_user) { create(:user, :guardian) }
    let(:guardian) { create(:guardian, user: guardian_user, email: guardian_user.email) }

    it "counts attendance and reports for an enrollment-backed child unchanged" do
      participant = create(:scheduled_lesson_enrollment)
      child = participant.enrollment.student_profile
      create(:student_guardianship, guardian:, student_profile: child, status: "active")
      lesson = participant.scheduled_lesson
      lesson.update!(status: "completed", started_at: 1.hour.ago, ended_at: Time.current,
                     completed_at: Time.current, attendance_status: "locked")
      create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: participant,
                                 status: "present")
      reviewed_report_for(lesson, participant)

      result = described_class.new(user: guardian_user, child_id: child.id).call

      expect(result[:attendance][:total]).to eq(1)
      expect(result[:reports_count]).to eq(1)
    end

    it "counts attendance and reports for a fee-plan-only direct-participation child" do
      child = create(:student_profile, :complete)
      create(:student_guardianship, guardian:, student_profile: child, status: "active")
      lesson = completed_lesson(course_offering: nil)
      participant = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment: nil,
                                                         student_profile: child)
      create(:lesson_attendance, scheduled_lesson: lesson, scheduled_lesson_enrollment: participant,
                                 status: "present")
      reviewed_report_for(lesson, participant)

      result = described_class.new(user: guardian_user, child_id: child.id).call

      expect(result[:attendance][:total]).to eq(1)
      expect(result[:attendance][:attended]).to eq(1)
      expect(result[:reports_count]).to eq(1)
    end
  end
end
