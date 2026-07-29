module Admin
  class BaseController < ApplicationController
    before_action :require_active_admin!

    private

    def require_active_admin!
      return if current_user&.admin? && current_user.active?

      render plain: I18n.t("admin.authorization.forbidden"), status: :forbidden
    end
  end
end
