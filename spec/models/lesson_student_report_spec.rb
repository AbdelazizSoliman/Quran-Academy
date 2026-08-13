require "rails_helper"

RSpec.describe LessonStudentReport do
  it "resolves the correct student through an enrollment-backed participation" do
    entry = create(:lesson_student_report)

    expect(entry.student_profile).to eq(entry.scheduled_lesson_enrollment.enrollment.student_profile)
  end

  it "resolves the correct student for a direct (enrollment-less) participation" do
    profile = create(:student_profile, :complete)
    lesson = create(:scheduled_lesson, course_offering: nil)
    report = create(:lesson_report, scheduled_lesson: lesson)
    participation = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment: nil,
                                                         student_profile: profile)
    entry = create(:lesson_student_report, lesson_report: report, scheduled_lesson_enrollment: participation)

    expect(entry.student_profile).to eq(profile)
  end
end
