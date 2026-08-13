module Parent
  class ScheduleController < BaseController
    def index
      @lessons = accessible_lessons.operational.chronological
                                   .where(starts_at: Time.current.beginning_of_day..30.days.from_now.end_of_day)
                                   .includes(:teacher_profile, :course_offering)
    end

    def show
      @lesson = accessible_lessons.includes(:teacher_profile, :course_offering).find(params.expect(:id))
      @students = guardian_students.joins(enrollments: :scheduled_lesson_enrollments)
                                   .where(scheduled_lesson_enrollments: { scheduled_lesson_id: @lesson.id }).distinct
    end

    private

    def accessible_lessons
      ScheduledLesson.joins(scheduled_lesson_enrollments: :enrollment)
                     .where(enrollments: { student_profile_id: guardian_students.select(:id) }).distinct
    end
  end
end
