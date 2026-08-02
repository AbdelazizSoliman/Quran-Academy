module Admin
  class NotificationsController < SchedulingBaseController
    SOURCE_TYPES = { "account_invitation" => AccountInvitation, "lesson_reminder" => ScheduledLesson,
                     "lesson_report" => LessonReport, "certificate" => Certificate }.freeze

    before_action :require_admin!, except: %i[index show]
    before_action :set_notification, only: %i[show retry_delivery]

    def index
      @pagy, @notifications = pagy(:offset, NotificationsQuery.new(params:).call, limit: 25)
    end

    def show
      @events = @notification.events.includes(:actor).recent_first
      @attempts = @notification.attempts.includes(:actor).chronological
    end

    def new
      @notification = Notification.new(notification_type: params[:notification_type],
                                       source_id: params[:source_id], recipient_user_id: params[:recipient_user_id])
    end

    def create
      deliver_notification(notification_params[:notification_type])
    end

    def send_account_invitation = deliver_notification("account_invitation")
    def send_lesson_reminder = deliver_notification("lesson_reminder")
    def send_lesson_report = deliver_notification("lesson_report")
    def send_certificate = deliver_notification("certificate")

    def retry_delivery
      @notification = Notifications::Attempt.new(notification: @notification, actor: current_user).call
      respond_to_dispatch
    end

    private

    def set_notification
      @notification = Notification.includes(:recipient_user, :actor, :source).find(params.expect(:id))
    end

    def notification_params
      params.expect(notification: %i[recipient_user_id notification_type channel source_id primary_guardian])
    end

    def channel = notification_params[:channel]
    def recipient = User.find(notification_params[:recipient_user_id])

    def deliver_notification(notification_type)
      source = SOURCE_TYPES.fetch(notification_type).find(notification_params[:source_id])

      @notification = Notifications::Dispatch.new(
        actor: current_user,
        recipient:,
        source:,
        type: notification_type,
        channel:,
        primary_guardian: notification_params[:primary_guardian]
      ).call

      respond_to_dispatch
    rescue ActiveRecord::RecordNotFound, KeyError
      head :not_found
    end

    def respond_to_dispatch
      if @notification.persisted? && @notification.errors.empty?
        redirect_to admin_notification_path(@notification), notice: t("notifications.messages.saved")
      else
        flash.now[:alert] = @notification.errors.full_messages.to_sentence
        render :new, status: :unprocessable_content
      end
    end
  end
end
