module Student
  class BaseController < ApplicationController
    before_action :require_student!

    private

    def require_student!
      return if current_user&.active? && current_user.student?

      render plain: t("authorization.forbidden"), status: :forbidden
    end
  end
end
