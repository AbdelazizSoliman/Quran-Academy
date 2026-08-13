module Parent
  class NotificationsController < BaseController
    def index
      @notifications = guardian_profile ? guardian_profile.received_notifications.recent_first.limit(100) : Notification.none
    end
  end
end
