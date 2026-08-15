module Parent
  class ScheduleController < BaseController
    def index
      @lessons = accessible_lessons.operational.chronological
                                   .where(starts_at: Time.current.beginning_of_day..30.days.from_now.end_of_day)
                                   .includes(:teacher_profile, :course_offering)
    end

    def show
      @lesson = accessible_lessons.includes(:teacher_profile, :course_offering).find(params.expect(:id))
      participant_ids = @lesson.scheduled_lesson_enrollments.filter_map { |item| item.student_profile&.id }
      @students = guardian_students.where(id: participant_ids)
    end

    private

    # scheduled_lesson_enrollments.enrollment_id is nullable (direct fee-plan-only participation
    # has none), so this has to resolve through the shared student-participation scope rather than
    # an inner join on :enrollment — otherwise a guardian's fee-plan-only child's lessons vanish here.
    def accessible_lessons
      participations = ScheduledLessonEnrollment.for_student_profile_ids(guardian_students.select(:id))
      ScheduledLesson.where(id: participations.select(:scheduled_lesson_id))
    end
  end
end
