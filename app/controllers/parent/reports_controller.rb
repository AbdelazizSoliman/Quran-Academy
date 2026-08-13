module Parent
  class ReportsController < BaseController
    def index
      student_ids = guardian_students.select(:id)
      enrollment_ids = Enrollment.where(student_profile_id: student_ids).select(:id)
      @assessments = StudentAssessment.where(student_profile_id: student_ids, status: "published")
                                      .includes(:assessment_template, :student_profile,
                                                scores: { assessment_rubric_item: :assessment_category })
                                      .recent_first
      @entries = LessonStudentReport.student_visible
                                    .joins(:scheduled_lesson_enrollment, lesson_report: :scheduled_lesson)
                                    .where(lesson_reports: { status: %w[reviewed locked] },
                                           scheduled_lesson_enrollments: { enrollment_id: enrollment_ids })
                                    .includes(scheduled_lesson_enrollment: { enrollment: { student_profile: :user } },
                                              lesson_report: { scheduled_lesson: %i[teacher_profile course_offering] })
                                    .order("scheduled_lessons.starts_at DESC")
    end
  end
end
