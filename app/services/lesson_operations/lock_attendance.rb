module LessonOperations
  class LockAttendance < Base
    def call
      return failed(:forbidden) unless administrator?
      return @lesson if @lesson.attendance_locked?
      return failed(:lesson_not_started) unless @lesson.started_at?
      return failed(:unresolved_attendance) if @lesson.lesson_attendances.unresolved.exists?

      ScheduledLesson.transaction { lock! }
      @lesson
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      failed(:stale_record)
    end

    private

    def lock!
      @lesson.update!(attendance_status: "locked", attendance_locked_at: Time.current,
                      attendance_locked_by: @actor, updated_by: @actor)
      event!(:attendance_locked, after_data: { "attendance_status" => "locked" })
      LessonAttendances::AuditLock.new(actor: @actor, lesson: @lesson).call!
    end
  end
end
