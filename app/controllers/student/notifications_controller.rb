module Student
  class NotificationsController < BaseController
    def index
      @notifications = Notification.where(recipient_user: current_user).includes(:source).recent_first.limit(100)
    end

    def show
      @notification = Notification.where(recipient_user: current_user).find(params.expect(:id))
    end
  end
end
