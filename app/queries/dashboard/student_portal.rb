module Dashboard
  class StudentPortal
    ATTENDED = %w[present late left_early].freeze

    def initialize(user:, now: Time.current)
      @profile = user.student_profile
      @now = now
    end

    def call
      return empty_result unless @profile

      lessons = @profile.scheduled_lessons
      {
        profile: @profile,
        today_lessons: lessons.where(starts_at: @now.in_time_zone.all_day)
                              .where(status: ScheduledLesson::OPERATIONAL_STATUSES + ["completed"])
                              .chronological.includes(:course_offering, :teacher_profile).to_a,
        upcoming_lessons: lessons.operational.where(starts_at: @now..30.days.from_now)
                                 .chronological.limit(5).includes(:course_offering, :teacher_profile).to_a,
        active_enrollments_count: @profile.enrollments.where(status: "active").count,
        attendance: attendance_summary,
        progress: @profile.student_progress,
        reports_count: visible_reports.count
      }
    end

    private

    def attendance_scope
      LessonAttendance.where(scheduled_lesson_enrollment_id: @profile.scheduled_lesson_enrollments.select(:id))
    end

    def attendance_summary
      total = attendance_scope.where(status: LessonAttendance::FINAL_STATUSES).count
      attended = attendance_scope.where(status: ATTENDED).count
      { total:, attended:, rate: total.zero? ? 0 : ((attended.to_f / total) * 100).round }
    end

    def visible_reports
      LessonStudentReport.student_visible.joins(:lesson_report)
                         .where(lesson_reports: { status: %w[reviewed locked] },
                                scheduled_lesson_enrollment_id: @profile.scheduled_lesson_enrollments.select(:id))
    end

    def empty_result
      { profile: nil, today_lessons: [], upcoming_lessons: [], active_enrollments_count: 0,
        attendance: { total: 0, attended: 0, rate: 0 }, progress: nil, reports_count: 0 }
    end
  end
end
