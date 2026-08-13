module Student
  class AttendancesController < ApplicationController
    before_action :require_student!

    def index
      @attendances = own_attendances.includes(scheduled_lesson: %i[teacher_profile course_offering])
                                    .order("scheduled_lessons.starts_at DESC").limit(100)
    end

    def show
      @attendance = own_attendances.includes(scheduled_lesson: %i[teacher_profile course_offering])
                                   .find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def own_attendances
      LessonAttendance.joins(:scheduled_lesson)
                      .where(scheduled_lesson_enrollment_id: current_user.student_profile
                                                                          .scheduled_lesson_enrollments.select(:id))
    end

    def require_student!
      return if current_user&.active? && current_user.student?

      render plain: t("authorization.forbidden"), status: :forbidden
    end
  end
end
