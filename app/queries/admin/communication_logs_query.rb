module Admin
  class CommunicationLogsQuery
    def initialize(params:, relation: CommunicationLog.all)
      @params = params
      @relation = relation
    end

    def call
      scope = @relation.includes(:actor, :student_profile, :guardian, scheduled_lesson: :teacher_profile)
                       .where(prepared_at: date_range)
      scope = scope.where(channel: @params[:channel]) if CommunicationLog::CHANNELS.include?(@params[:channel])
      scope = scope.where(status: @params[:status]) if CommunicationLog::STATUSES.include?(@params[:status])
      scope.recent_first
    end

    private

    def date_range
      from = parse_date(@params[:from]) || 30.days.ago.to_date
      to = parse_date(@params[:to]) || Date.current
      from.beginning_of_day..to.end_of_day
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
  end
end
