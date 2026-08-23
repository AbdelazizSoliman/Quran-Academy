module Teacher
  class OperationalMetrics
    def initialize(teacher_profile:, date: Date.current)
      @teacher = teacher_profile
      @lessons = if teacher_profile
                   teacher_profile.scheduled_lessons.where(starts_at: date.all_month)
                 else
                   ScheduledLesson.none
                 end
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
      submitted = @teacher ? @teacher.lesson_reports.where(status: %w[submitted reviewed locked]).count : 0
      { submitted_reports: submitted }
    end
  end
end
