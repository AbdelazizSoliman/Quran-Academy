module Teacher
  class PayrollsController < ApplicationController
    before_action -> { require_release_feature!(:payroll) }
    before_action :require_teacher!

    def index
      @payrolls = own_payrolls.recent_first
    end

    def show
      @payroll = own_payrolls.includes(items: :scheduled_lesson).find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def own_payrolls = current_user.teacher_profile.teacher_payrolls.where.not(status: "draft")

    def require_teacher!
      return if current_user&.active? && current_user.teacher?

      render plain: t("admin.authorization.forbidden"), status: :forbidden
    end
  end
end
