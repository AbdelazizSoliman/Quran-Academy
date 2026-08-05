module Dashboard
  class Overview
    OPERATIONAL_LESSON_STATUSES = %w[scheduled in_progress completed].freeze
    ATTENDED_STATUSES = %w[present late left_early].freeze

    def initialize(user:, now: Time.current)
      @user = user
      @now = now
    end

    def call
      {
        statistics: statistics,
        lessons: todays_lessons.limit(5).includes(:teacher_profile).to_a,
        late_attendances: late_attendances.limit(5).to_a
      }
    end

    private

    def statistics
      {
        students: ::StudentProfile.count,
        active_students: active_students_count,
        teachers: ::TeacherProfile.count,
        active_teachers: active_teachers_count,
        lessons: todays_lessons.count,
        remaining_lessons: todays_lessons.where("starts_at > ?", @now).count,
        attendance: attendance_statistics
      }
    end

    def active_students_count
      ::StudentProfile.where(learning_status: "active").count
    end

    def active_teachers_count
      ::TeacherProfile.where(employment_status: "active").count
    end

    def todays_lessons
      @todays_lessons ||= accessible_lessons
                          .where(starts_at: today_range)
                          .where(status: OPERATIONAL_LESSON_STATUSES)
                          .order(:starts_at, :id)
    end

    def accessible_lessons
      return ::ScheduledLesson.all if @user.admin? || @user.staff?
      return teacher_lessons if @user.teacher?

      student_lessons
    end

    def teacher_lessons
      ::ScheduledLesson.where(teacher_profile_id: @user.teacher_profile&.id)
    end

    def student_lessons
      student_enrollment_ids = @user.student_profile&.enrollments&.select(:id)
      return ::ScheduledLesson.none unless student_enrollment_ids

      ::ScheduledLesson.joins(:scheduled_lesson_enrollments)
                     .where(scheduled_lesson_enrollments: { enrollment_id: student_enrollment_ids })
                     .distinct
    end

    def attendance_scope
      scope = ::LessonAttendance.joins(:scheduled_lesson_enrollment)
                              .where(scheduled_lesson_id: todays_lessons.select(:id))
      return scope unless @user.student?

      scope.where(scheduled_lesson_enrollments: { enrollment_id: @user.student_profile&.enrollments&.select(:id) })
    end

    def attendance_statistics
      total = attendance_scope.where(status: ::LessonAttendance::FINAL_STATUSES).count
      attended = attendance_scope.where(status: ATTENDED_STATUSES).count

      { total:, attended:, rate: total.zero? ? 0 : ((attended.to_f / total) * 100).round }
    end

    def late_attendances
      attendance_scope.where(status: "late")
                      .includes(scheduled_lesson: :teacher_profile,
                                scheduled_lesson_enrollment: { enrollment: :student_profile })
                      .order(arrival_at: :desc, id: :desc)
    end

    def today_range
      @now.in_time_zone.all_day
    end
  end
end
