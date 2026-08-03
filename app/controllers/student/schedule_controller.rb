module Student
  class ScheduleController < ApplicationController
    before_action :require_student!

    def index
      @lessons = upcoming_lessons(current_user.student_profile)
    end

    def show
      @lesson = current_user.student_profile.scheduled_lessons.operational
                            .includes(:teacher_profile, :course_offering,
                                      scheduled_lesson_enrollments: { enrollment: :student_profile })
                            .find(params.expect(:id))
      @participant = expected_participant
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def expected_participant
      @lesson.scheduled_lesson_enrollments.find do |item|
        item.enrollment.student_profile.user_id == current_user.id && item.expected?
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
