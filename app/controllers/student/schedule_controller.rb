module Student
  class ScheduleController < ApplicationController
    before_action :require_student!

    def index
      @lessons = upcoming_lessons(current_user.student_profile)
    end

    def show
      @lesson = current_user.student_profile.scheduled_lessons.operational
                            .includes(:teacher_profile, :course_offering).find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def upcoming_lessons(profile)
      return ScheduledLesson.none unless profile

      profile.scheduled_lessons.operational.chronological.where(starts_at: Time.current..30.days.from_now)
    end

    def require_student!
      return if current_user&.active? && current_user.student?

      render plain: t("authorization.forbidden"), status: :forbidden
    end
  end
end
