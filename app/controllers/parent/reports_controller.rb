module Parent
  class ReportsController < BaseController
    def index
      student_ids = guardian_students.select(:id)
      @assessments = StudentAssessment.where(student_profile_id: student_ids, status: "published")
                                      .includes(:assessment_template, :student_profile,
                                                scores: { assessment_rubric_item: :assessment_category })
                                      .recent_first
      @entries = visible_entries(student_ids)
    end

    private

    def visible_entries(student_ids)
      participations = ScheduledLessonEnrollment.for_student_profile_ids(student_ids)
      LessonStudentReport.student_visible
                         .joins(lesson_report: :scheduled_lesson)
                         .where(lesson_reports: { status: %w[reviewed locked] },
                                scheduled_lesson_enrollment_id: participations.select(:id))
                         .includes(scheduled_lesson_enrollment: [:student_profile,
                                                                 { enrollment: { student_profile: :user } }],
                                   lesson_report: { scheduled_lesson: %i[teacher_profile course_offering] })
                         .order("scheduled_lessons.starts_at DESC")
    end
  end
end
