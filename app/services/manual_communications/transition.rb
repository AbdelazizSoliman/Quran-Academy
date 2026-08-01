module ManualCommunications
  class Transition
    def initialize(actor:, log:, action:)
      @actor = actor
      @log = log
      @action = action.to_sym
    end

    def call
      return invalid(:forbidden) unless authorized?

      target = { mark_opened: "opened", confirm_sent: "confirmed_sent", cancel: "cancelled" }.fetch(@action)
      return @log if @log.status == target
      return invalid(:invalid_transition) unless valid_transition?(target)

      CommunicationLog.transaction { transition!(target) }
      @log
    rescue ActiveRecord::RecordInvalid
      invalid(:stale_record)
    end

    private

    def transition!(target)
      previous = @log.status
      attributes = { status: target }
      attributes[:opened_at] = Time.current if target == "opened"
      attributes.merge!(confirmed_sent_at: Time.current, confirmed_by: @actor) if target == "confirmed_sent"
      @log.update!(attributes)
      CommunicationLogEvent.create!(communication_log: @log, actor: @actor, event_type: target,
                                    before_data: { "status" => previous }, after_data: { "status" => target })
    end

    def authorized? = @actor.active? && (@actor.admin? || @log.actor_id == @actor.id)
    def valid_transition?(target) = target == "cancelled" || @log.status.in?(%w[prepared opened])

    def invalid(error)
      @log.errors.add(:base, error)
      @log
    end
  end
end
