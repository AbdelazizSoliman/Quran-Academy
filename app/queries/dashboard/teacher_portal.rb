module Dashboard
  class TeacherPortal
    def initialize(user:, now: Time.current)
      @user = user
      @profile = user.teacher_profile
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
        students_count: taught_students_count,
        week_lessons_count: lessons.where(starts_at: @now.beginning_of_week..@now.end_of_week)
                                   .where.not(status: %w[cancelled archived]).count,
        pending_reports_count: LessonReport.where(teacher_profile: @profile, status: %w[draft reopened]).count,
        completed_lessons_count: lessons.where(status: "completed").count
      }
    end

    private

    def taught_students_count
      Enrollment.joins(scheduled_lesson_enrollments: :scheduled_lesson)
                .where(scheduled_lessons: { teacher_profile_id: @profile.id })
                .distinct.count(:student_profile_id)
    end

    def empty_result
      { profile: nil, today_lessons: [], upcoming_lessons: [], students_count: 0,
        week_lessons_count: 0, pending_reports_count: 0, completed_lessons_count: 0 }
    end
  end
end
