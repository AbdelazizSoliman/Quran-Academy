module Student
  class ReportsController < ApplicationController
    before_action :require_student!

    def index
      @entries = visible_entries.includes(lesson_report: { scheduled_lesson: %i[teacher_profile course_offering] })
                                .order("scheduled_lessons.starts_at DESC")
    end

    def show
      @entry = visible_entries.includes(lesson_report: { scheduled_lesson: %i[teacher_profile course_offering] })
                              .find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def visible_entries
      LessonStudentReport.student_visible.joins(lesson_report: :scheduled_lesson)
                         .where(lesson_reports: { status: %w[reviewed locked] },
                                scheduled_lesson_enrollment_id: current_user.student_profile
                                                                             .scheduled_lesson_enrollments.select(:id))
                         .where(scheduled_lessons: { status: "completed" })
    end

    def require_student!
      return if current_user&.active? && current_user.student?

      render plain: t("authorization.forbidden"), status: :forbidden
    end
  end
end
