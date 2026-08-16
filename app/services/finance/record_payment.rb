module Finance
  class RecordPayment
    def initialize(actor:, invoice:, attributes: {})
      @actor = actor
      @invoice = invoice
      @attributes = attributes
    end

    def call
      payment = build_payment
      validate_operation(payment)
      return payment if payment.errors.any?

      FinancePayment.transaction { persist_payment!(payment) }
      payment
    rescue ActiveRecord::RecordInvalid => e
      e.record
    end

    def refund(payment)
      return invalid_payment(payment, :forbidden) unless authorized?
      return invalid_payment(payment, :already_refunded) if payment.refunded?

      FinancePayment.transaction { refund_payment!(payment) }
      payment
    rescue ActiveRecord::RecordInvalid
      invalid_payment(payment, :refund_failed)
    end

    private

    def authorized? = @actor&.active? && @actor.admin?

    def build_payment
      @invoice.payments.new(@attributes.merge(currency: @invoice.currency, recorded_by: @actor))
    end

    def validate_operation(payment)
      payment.errors.add(:base, :forbidden) unless authorized?
      payment.errors.add(:base, :invalid_transition) unless @invoice.status.in?(%w[issued partially_paid overdue])
      payment.errors.add(:amount, :less_than_or_equal_to, count: @invoice.balance_due) if overpayment?(payment)
    end

    def persist_payment!(payment)
      payment.save!
      record_ledger!(payment, "payment_received", payment.received_on, "cash", "accounts_receivable")
      update_invoice_status!
    end

    def refund_payment!(payment)
      payment.update!(status: "refunded", refunded_at: Time.current, refunded_by: @actor)
      record_ledger!(payment, "payment_refunded", Date.current, "accounts_receivable", "cash")
      update_invoice_status!
    end

    def record_ledger!(payment, entry_type, occurred_on, debit, credit)
      entry = { entry_type:, occurred_on:, currency: payment.currency, amount: payment.amount }
      Finance::Ledger.record_pair!(source: payment, actor: @actor, debit:, credit:, entry:)
    end

    def overpayment?(payment)
      payment.amount.to_d.positive? && payment.amount.to_d > @invoice.balance_due
    end

    def update_invoice_status!
      @invoice.reload
      status = if @invoice.balance_due.zero?
                 "paid"
               elsif @invoice.paid_amount.positive?
                 "partially_paid"
               else
                 "issued"
               end
      @invoice.update!(status:, updated_by: @actor)
    end

    def invalid_payment(payment, error)
      payment.errors.add(:base, error)
      payment
    end
  end
end
