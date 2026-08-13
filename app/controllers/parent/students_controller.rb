module Parent
  class StudentsController < BaseController
    def index
      @students = guardian_students.includes(:user, :student_progress, :assigned_teacher_profile)
    end

    def show
      set_guardian_student
      @upcoming_lessons = @student.scheduled_lessons.operational.chronological
                                  .where(starts_at: Time.current..30.days.from_now).limit(5)
                                  .includes(:teacher_profile, :course_offering)
      @recent_reports = visible_reports_for(@student).limit(5)
    end

    private

    def visible_reports_for(student)
      LessonStudentReport.student_visible
                         .joins(lesson_report: :scheduled_lesson)
                         .where(lesson_reports: { status: %w[reviewed locked] },
                                scheduled_lesson_enrollment_id: student.scheduled_lesson_enrollments.select(:id))
                         .includes(lesson_report: { scheduled_lesson: :teacher_profile })
                         .order("scheduled_lessons.starts_at DESC")
    end
  end
end
