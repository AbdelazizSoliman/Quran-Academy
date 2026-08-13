module Parent
  class AttendancesController < BaseController
    def index
      participations = ScheduledLessonEnrollment.for_student_profile_ids(guardian_students.select(:id))
      @attendances = LessonAttendance.joins(:scheduled_lesson)
                                     .where(scheduled_lesson_enrollment_id: participations.select(:id))
                                     .includes(scheduled_lesson_enrollment: [
                                                 :student_profile, { enrollment: { student_profile: :user } }
                                               ], scheduled_lesson: %i[teacher_profile course_offering])
                                     .order("scheduled_lessons.starts_at DESC").limit(150)
    end
  end
end
