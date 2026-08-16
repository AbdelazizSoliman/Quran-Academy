module Finance
  class ExpenseOperation
    RULES = {
      approve: { from: "draft", to: "approved", timestamp: :approved_at, actor: :approved_by },
      pay: { from: "approved", to: "paid", timestamp: :paid_at, actor: :paid_by },
      cancel: { from: %w[draft approved], to: "cancelled", timestamp: :cancelled_at, actor: :cancelled_by }
    }.freeze

    def initialize(actor:, expense: nil, attributes: {})
      @actor = actor
      @expense = expense
      @attributes = attributes
    end

    def create
      expense = FinanceExpense.new(@attributes.merge(created_by: @actor))
      expense.errors.add(:base, :forbidden) unless authorized?
      expense.save if expense.errors.empty?
      expense
    end

    def transition(action)
      return invalid(:forbidden) unless authorized?

      rule = RULES.fetch(action.to_sym)
      error = transition_error(action, rule)
      return invalid(error) if error

      FinanceExpense.transaction { apply_transition_and_ledger!(action, rule) }
      @expense
    rescue ActiveRecord::RecordInvalid
      invalid(:transition_failed)
    end

    private

    def authorized? = @actor&.active? && @actor.admin?

    def transition_error(action, rule)
      return :invalid_transition unless @expense.status.in?(Array(rule[:from]))

      :payment_method_required if action.to_sym == :pay && @expense.payment_method.blank?
    end

    def apply_transition!(rule)
      @expense.update!(status: rule[:to], rule[:timestamp] => Time.current, rule[:actor] => @actor)
    end

    def apply_transition_and_ledger!(action, rule)
      apply_transition!(rule)
      record_payment! if action.to_sym == :pay
    end

    def record_payment!
      entry = { entry_type: "expense_paid", occurred_on: @expense.incurred_on,
                currency: @expense.currency, amount: @expense.amount }
      Finance::Ledger.record_pair!(source: @expense, actor: @actor, debit: "expense", credit: "cash", entry:)
    end

    def invalid(error)
      @expense.errors.add(:base, error)
      @expense
    end
  end
end
