module Teacher
  class BaseController < ApplicationController
    before_action :require_active_teacher!

    private

    def require_active_teacher!
      return if current_user&.teacher? && current_user.active?

      render plain: I18n.t("teacher.authorization.forbidden"), status: :forbidden
    end
  end
end
