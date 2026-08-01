module Teacher
  class OperationalMetrics
    def initialize(teacher_profile:, date: Date.current)
      @teacher = teacher_profile
      @lessons = teacher_profile.scheduled_lessons.where(starts_at: date.all_month)
    end

    def call
      lesson_metrics.merge(report_metrics)
    end

    private

    def lesson_metrics
      { lessons: @lessons.count,
        completed: @lessons.where(status: "completed").count,
        cancelled: @lessons.where(status: "cancelled").count,
        hours: @lessons.where(status: "completed").sum("EXTRACT(EPOCH FROM (ends_at - starts_at))") / 3600,
        late_check_ins: @lessons.where(teacher_attendance_status: "late").count }
    end

    def report_metrics
      { submitted_reports: @teacher.lesson_reports.where(status: %w[submitted reviewed locked]).count }
    end
  end
end
