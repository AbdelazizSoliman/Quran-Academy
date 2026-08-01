module Teacher
  class LessonAttendancesController < ApplicationController
    before_action :require_teacher!
    before_action :set_lesson
    before_action :set_attendance

    def record_arrival
      perform LessonAttendances::RecordArrival.new(actor: current_user, attendance: @attendance)
    end

    def mark_present
      perform LessonAttendances::MarkPresent.new(actor: current_user, attendance: @attendance)
    end

    def mark_absent
      perform LessonAttendances::MarkAbsent.new(actor: current_user, attendance: @attendance)
    end

    def excuse
      perform LessonAttendances::Excuse.new(actor: current_user, attendance: @attendance, reason: params[:reason])
    end

    def record_departure
      perform LessonAttendances::RecordDeparture.new(actor: current_user, attendance: @attendance)
    end

    private

    def set_lesson
      @lesson = current_user.teacher_profile.scheduled_lessons.find(params.expect(:schedule_id))
    end

    def set_attendance
      @attendance = @lesson.lesson_attendances.find(params.expect(:id))
    end

    def perform(operation)
      @attendance = operation.call
      options = if @attendance.errors.empty?
                  { notice: t("attendance.messages.updated") }
                else
                  { alert: @attendance.errors.full_messages.to_sentence }
                end
      redirect_to attendance_teacher_schedule_path(@lesson), **options, status: :see_other
    end

    def require_teacher!
      return if current_user&.active? && current_user.teacher?

      render plain: t("authorization.forbidden"), status: :forbidden
    end
  end
end
