module LessonReports
  class Initialize
    def initialize(actor:, lesson:)
      @actor = actor
      @lesson = lesson
    end

    def call
      return invalid_report(:ineligible_lesson) unless eligible?

      LessonReport.transaction do
        report = @lesson.lesson_report || create_report!
        create_missing_entries!(report) if report.teacher_editable?
        report
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      @lesson.lesson_report || invalid_report(:initialization_failed)
    end

    private

    def eligible?
      @lesson.status.in?(%w[in_progress completed]) && !@lesson.archived? && !@lesson.cancelled?
    end

    def create_report!
      report = LessonReport.create!(scheduled_lesson: @lesson, teacher_profile: @lesson.teacher_profile,
                                    report_language: @actor.preferred_locale,
                                    created_by: @actor, updated_by: @actor)
      LessonReportEvent.create!(lesson_report: report, actor: @actor, event_type: "created",
                                after_data: { "status" => "draft" })
      report
    end

    def create_missing_entries!(report)
      @lesson.scheduled_lesson_enrollments.includes(:lesson_attendance).find_each do |participant|
        next unless participant.expected?

        create_entry!(report, participant) unless report.lesson_student_reports.exists?(
          scheduled_lesson_enrollment_id: participant.id
        )
      end
    end

    def create_entry!(report, participant)
      status = academic_entry_status(participant.lesson_attendance)
      entry = LessonStudentReport.create!(lesson_report: report, scheduled_lesson_enrollment: participant, status:,
                                          created_by: @actor, updated_by: @actor)
      LessonStudentReportEvent.create!(lesson_student_report: entry, actor: @actor, event_type: "created",
                                       after_data: { "status" => status })
    end

    def academic_entry_status(attendance)
      attendance&.status.in?(%w[absent excused_absence lesson_cancelled not_applicable]) ? "not_applicable" : "pending"
    end

    def invalid_report(error)
      report = @lesson.lesson_report || @lesson.build_lesson_report(teacher_profile: @lesson.teacher_profile,
                                                                    created_by: @actor, updated_by: @actor)
      report.errors.add(:base, error)
      report
    end
  end
end
