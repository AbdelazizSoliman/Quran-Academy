class DashboardController < ApplicationController
  def index
    @dashboard = Dashboard::Overview.new(user: current_user).call
  end
end
