module Teacher
  class ReportsController < ApplicationController
    before_action :require_teacher!

    def show
      @metrics = OperationalMetrics.new(teacher_profile: current_user.teacher_profile).call
    end

    private

    def require_teacher!
      return if current_user&.active? && current_user.teacher?

      render plain: t("admin.authorization.forbidden"), status: :forbidden
    end
  end
end
