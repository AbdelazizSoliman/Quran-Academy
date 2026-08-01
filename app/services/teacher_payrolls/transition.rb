module TeacherPayrolls
  class Transition
    RULES = {
      prepare: { from: %w[draft], to: "prepared", timestamp: :prepared_at, actor: :prepared_by },
      approve: { from: %w[prepared], to: "approved", timestamp: :approved_at, actor: :approved_by },
      pay: { from: %w[approved], to: "paid", timestamp: :paid_at, actor: :paid_by },
      reopen: { from: %w[prepared approved], to: "draft" },
      cancel: { from: %w[draft prepared approved], to: "cancelled", timestamp: :cancelled_at, actor: :cancelled_by }
    }.freeze

    def initialize(actor:, payroll:, action:, reason: nil)
      @actor = actor
      @payroll = payroll
      @action = action.to_sym
      @reason = reason.to_s.strip
    end

    def call
      rule = RULES.fetch(@action)
      return invalid(validation_error(rule)) if validation_error(rule)
      return @payroll if @payroll.status == rule[:to]

      TeacherPayroll.transaction { transition!(rule) }
      @payroll
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      invalid(:stale_record)
    end

    private

    def validation_error(rule)
      return :forbidden unless @actor.active? && @actor.admin?
      return :reason_required if @action.in?(%i[reopen cancel]) && @reason.blank?

      :invalid_transition unless @payroll.status.in?(rule[:from]) || @payroll.status == rule[:to]
    end

    def transition!(rule)
      previous = @payroll.status
      @payroll.update!(transition_attributes(rule))
      TeacherPayrollEvent.create!(teacher_payroll: @payroll, actor: @actor, event_type: event_type,
                                  before_data: { "status" => previous }, after_data: { "status" => rule[:to] },
                                  metadata: reason_metadata)
    end

    def transition_attributes(rule)
      attributes = { status: rule[:to], updated_by: @actor }
      attributes[rule[:timestamp]] = Time.current if rule[:timestamp]
      attributes[rule[:actor]] = @actor if rule[:actor]
      attributes[:cancellation_reason] = @reason if @action == :cancel
      attributes[:adjustment_reason] = @reason if @action == :reopen
      attributes
    end

    def event_type
      { prepare: "prepared", approve: "approved", pay: "paid", reopen: "reopened", cancel: "cancelled" }.fetch(@action)
    end

    def reason_metadata = @reason.present? ? { "reason" => @reason } : {}

    def invalid(error)
      @payroll.errors.add(:base, error)
      @payroll
    end
  end
end
