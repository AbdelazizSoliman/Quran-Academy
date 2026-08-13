class DashboardController < ApplicationController
  def index
    @portal = case current_user.role
              when "teacher" then Dashboard::TeacherPortal.new(user: current_user).call
              when "student" then Dashboard::StudentPortal.new(user: current_user).call
              when "guardian" then Dashboard::GuardianPortal.new(user: current_user, child_id: params[:child_id]).call
              end

    return if @portal

    @dashboard = Dashboard::Overview.new(user: current_user).call
  end
end
