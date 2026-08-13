module Admin
  class LessonAttendancesController < SchedulingBaseController
    before_action :require_admin!, except: %i[index show]
    before_action :set_lesson, except: :index
    before_action :set_attendance, except: %i[index show]

    def index
      @pagy, @attendances = pagy(:offset, LessonAttendancesQuery.new(params:).call, limit: 25)
    end

    def show
      @attendances = @lesson.lesson_attendances.includes(
        :events, scheduled_lesson_enrollment: [:student_profile, { enrollment: :student_profile }]
      )
      @events = @lesson.events.includes(:actor).recent_first.limit(50)
    end

    def record_arrival
      perform LessonAttendances::RecordArrival.new(actor: current_user, attendance: @attendance)
    end

    def mark_present
      perform LessonAttendances::MarkPresent.new(actor: current_user, attendance: @attendance)
    end

    def mark_absent
      perform LessonAttendances::MarkAbsent.new(actor: current_user, attendance: @attendance, override: true,
                                                reason: params[:reason])
    end

    def excuse
      perform LessonAttendances::Excuse.new(actor: current_user, attendance: @attendance, reason: params[:reason])
    end

    def record_departure
      perform LessonAttendances::RecordDeparture.new(actor: current_user, attendance: @attendance)
    end

    def adjust
      attributes = params.permit(:status, :reason, :arrival_at, :departure_at).to_h.symbolize_keys
      perform LessonAttendances::Adjust.new(actor: current_user, attendance: @attendance, attributes:)
    end

    private

    def set_lesson
      @lesson = ScheduledLesson.find(params.expect(:scheduled_lesson_id))
    end

    def set_attendance
      @attendance = @lesson.lesson_attendances.find(params.expect(:id))
    end

    def perform(operation)
      @attendance = operation.call
      redirect_to attendance_admin_scheduled_lesson_path(@lesson),
                  **response_options(@attendance, "attendance.messages.updated")
    end

    def response_options(record, key)
      if record.errors.empty?
        { notice: t(key), status: :see_other }
      else
        { alert: record.errors.full_messages.to_sentence, status: :see_other }
      end
    end
  end
end
