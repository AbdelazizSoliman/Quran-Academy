module Teacher
  class NotificationsController < BaseController
    before_action :set_notification, only: :show

    def index
      @notifications = Notification.where(actor: current_user).or(Notification.where(recipient_user: current_user))
                                   .includes(:recipient_user, :source).recent_first.limit(100)
    end

    def show; end

    def create
      source = source_class.find(notification_params[:source_id])
      recipient = User.find(notification_params[:recipient_user_id])
      notification = Notifications::Dispatch.new(actor: current_user, recipient:, source:,
                                                 type: notification_params[:notification_type],
                                                 channel: notification_params[:channel],
                                                 primary_guardian: notification_params[:primary_guardian]).call
      if notification.persisted?
        redirect_to teacher_notification_path(notification), notice: t("notifications.messages.saved")
      else
        redirect_to teacher_notifications_path, alert: notification.errors.full_messages.to_sentence
      end
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def set_notification
      @notification = Notification.where(actor: current_user).or(Notification.where(recipient_user: current_user))
                                  .find(params.expect(:id))
    end

    def notification_params
      params.expect(notification: %i[recipient_user_id notification_type channel source_id primary_guardian])
    end

    def source_class
      notification_params[:notification_type] == "lesson_report" ? LessonReport : ScheduledLesson
    end
  end
end
