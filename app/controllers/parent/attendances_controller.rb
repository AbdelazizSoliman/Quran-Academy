module Parent
  class AttendancesController < BaseController
    def index
      @attendances = LessonAttendance.joins(:scheduled_lesson, scheduled_lesson_enrollment: :enrollment)
                                     .where(enrollments: { student_profile_id: guardian_students.select(:id) })
                                     .includes(scheduled_lesson_enrollment: { enrollment: { student_profile: :user } },
                                               scheduled_lesson: %i[teacher_profile course_offering])
                                     .order("scheduled_lessons.starts_at DESC").limit(150)
    end
  end
end
