module Admin
  class NotificationsQuery
    def initialize(params:, relation: Notification.all)
      @params = params
      @relation = relation
    end

    def call
      scope = @relation.includes(:recipient_user, :actor, :source).where(created_at: date_range)
      scope = scope.where(channel: @params[:channel]) if Notification::CHANNELS.include?(@params[:channel])
      scope = scope.where(status: @params[:status]) if Notification::STATUSES.include?(@params[:status])
      scope = scope.where(notification_type: @params[:notification_type]) if type_filter?
      scope = scope.where(recipient_user_id: @params[:recipient_user_id]) if @params[:recipient_user_id].present?
      scope.recent_first
    end

    private

    def type_filter? = Notification::TYPES.include?(@params[:notification_type])

    def date_range
      (date(@params[:from]) || 3.months.ago.to_date).beginning_of_day..
        (date(@params[:to]) || Date.current).end_of_day
    end

    def date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
  end
end
