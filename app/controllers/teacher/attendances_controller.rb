module Teacher
  class AttendancesController < BaseController
    def index
      @attendances = teacher_attendances
      @status_counts = @attendances.unscope(:order).group(:status).count
      @attendances = @attendances.where(status: selected_status) if selected_status
      @attendances = @attendances.limit(100)
    end

    private

    def teacher_attendances
      LessonAttendance
        .joins(:scheduled_lesson)
        .where(scheduled_lessons: { teacher_profile_id: current_user.teacher_profile.id })
        .includes(:scheduled_lesson,
                  scheduled_lesson_enrollment: [:student_profile, { enrollment: { student_profile: :user } }])
        .order("scheduled_lessons.starts_at DESC", id: :desc)
    end

    def selected_status
      status = params.permit(:status)[:status]
      status if status.in?(LessonAttendance::STATUSES)
    end
  end
end
