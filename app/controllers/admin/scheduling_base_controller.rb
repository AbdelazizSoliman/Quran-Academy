module Admin
  class SchedulingBaseController < ApplicationController
    before_action :require_admin_or_staff!

    private

    def require_admin_or_staff!
      return if current_user&.active? && current_user.role.in?(%w[admin staff])

      render plain: I18n.t("admin.authorization.forbidden"), status: :forbidden
    end

    def require_admin!
      return if current_user&.active? && current_user.admin?

      render plain: I18n.t("admin.authorization.forbidden"), status: :forbidden
    end
  end
end
