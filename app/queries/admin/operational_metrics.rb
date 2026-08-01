module Admin
  class OperationalMetrics
    def initialize(date: Date.current)
      @date = date
    end

    def call
      people_metrics.merge(lesson_metrics, attendance_metrics, report_metrics, payroll_metrics)
    end

    private

    def lessons = ScheduledLesson.where(starts_at: @date.all_month)

    def people_metrics
      { active_students: StudentProfile.where(learning_status: "active").count,
        active_teachers: TeacherProfile.where(employment_status: "active").count }
    end

    def lesson_metrics
      { lessons_today: lessons.where(starts_at: @date.all_day).count,
        lessons_this_week: lessons.where(starts_at: @date.all_week).count,
        completed_lessons: lessons.where(status: "completed").count,
        cancelled_lessons: lessons.where(status: "cancelled").count }
    end

    def attendance_metrics
      { attendance_percentage: attendance_percentage,
        late_students: LessonAttendance.where(status: "late", recorded_at: @date.all_month).count,
        late_teachers: lessons.where(teacher_attendance_status: "late").count }
    end

    def report_metrics
      { pending_reports: LessonReport.where(status: %w[draft submitted reopened]).count,
        locked_reports: LessonReport.where(status: "locked").count }
    end

    def payroll_metrics
      { prepared_payrolls: TeacherPayroll.where(status: "prepared").count,
        approved_payrolls: TeacherPayroll.where(status: "approved").count,
        paid_payrolls: TeacherPayroll.where(status: "paid").count }
    end

    def attendance_percentage
      finalized = LessonAttendance.where(recorded_at: @date.all_month).where.not(status: "pending")
      return 0 if finalized.empty?

      attended = finalized.where(status: %w[present late left_early]).count
      (attended * 100.0 / finalized.count).round(1)
    end
  end
end
