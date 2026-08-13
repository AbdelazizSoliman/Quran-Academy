module Student
  class ScheduleController < ApplicationController
    before_action :require_student!

    def index
      @lessons = upcoming_lessons(current_user.student_profile)
    end

    def show
      set_lesson
      @participant = expected_participant
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def join
      set_lesson
      @participant = expected_participant
      return head :not_found unless @participant

      join_student_to_meeting
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def join_student_to_meeting
      destination = @lesson.safe_online_meeting_join_url
      return redirect_to(student_schedule_path(@lesson), alert: t("scheduling.join.invalid_url")) unless destination

      attendance = LessonAttendances::Join.new(actor: current_user, lesson: @lesson,
                                               participation: @participant).call
      if attendance.errors.any?
        return redirect_to(student_schedule_path(@lesson), alert: attendance.errors.full_messages.to_sentence)
      end

      redirect_to destination, allow_other_host: true
    end

    def set_lesson
      @lesson = current_user.student_profile.scheduled_lessons.operational
                            .includes(:teacher_profile, :course_offering,
                                      scheduled_lesson_enrollments: [
                                        :student_profile, { enrollment: :student_profile }
                                      ])
                            .find(params.expect(:id))
    end

    def expected_participant
      @lesson.scheduled_lesson_enrollments.find do |item|
        item.student_profile&.user_id == current_user.id && item.expected?
      end
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

    def require_student!
      return if current_user&.active? && current_user.student?

      render plain: t("authorization.forbidden"), status: :forbidden
    end
  end
end
