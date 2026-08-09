module Teacher
  class ScheduleController < ApplicationController
    before_action :require_teacher!

    def index
      @lessons = upcoming_lessons(current_user.teacher_profile)
    end

    def show
      set_lesson
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def attendance
      set_lesson
      @attendances = @lesson.lesson_attendances.includes(
        scheduled_lesson_enrollment: { enrollment: :student_profile }
      )
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def join
      @lesson = owned_lesson
      join_teacher_to_meeting
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def check_in
      operate LessonOperations::CheckIn.new(actor: current_user, lesson: owned_lesson)
    end

    def start
      operate LessonOperations::Start.new(actor: current_user, lesson: owned_lesson)
    end

    def complete
      options = { mark_unresolved_absent: params[:mark_unresolved_absent], notes: params[:completion_notes] }
      operate LessonOperations::Complete.new(actor: current_user, lesson: owned_lesson, options:)
    end

    private

    def join_teacher_to_meeting
      destination = @lesson.safe_online_meeting_join_url
      return redirect_to(teacher_schedule_path(@lesson), alert: t("scheduling.join.invalid_url")) unless destination

      @lesson = LessonOperations::CheckIn.new(actor: current_user, lesson: @lesson).call
      if @lesson.errors.any?
        return redirect_to(teacher_schedule_path(@lesson), alert: @lesson.errors.full_messages.to_sentence)
      end

      redirect_to destination, allow_other_host: true
    end

    def set_lesson
      @lesson = owned_lesson
    end

    def owned_lesson
      current_user.teacher_profile.scheduled_lessons.includes(:course_offering).find(params.expect(:id))
    end

    def operate(operation)
      @lesson = operation.call
      destination = @lesson.errors.empty? ? attendance_teacher_schedule_path(@lesson) : teacher_schedule_path(@lesson)
      options = if @lesson.errors.empty?
                  { notice: t("attendance.messages.updated") }
                else
                  { alert: @lesson.errors.full_messages.to_sentence }
                end
      redirect_to destination, **options, status: :see_other
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def upcoming_lessons(profile)
      return ScheduledLesson.none unless profile

      profile.scheduled_lessons.operational.chronological.where(starts_at: schedule_window)
    end

    def schedule_window
      zone_name = AcademySetting.current_or_nil&.default_time_zone || "Cairo"
      academy_now = Time.current.in_time_zone(zone_name)
      academy_now.beginning_of_day..(academy_now + 30.days).end_of_day
    end

    def require_teacher!
      return if current_user&.active? && current_user.teacher?

      render plain: t("authorization.forbidden"), status: :forbidden
    end
  end
end
