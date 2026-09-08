module Public
  class BaseController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_session_version!
    layout "public"

    private

    def public_locale_selection? = true
  end
end
