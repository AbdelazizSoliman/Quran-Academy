module Finance
  class InvoiceOperation
    def initialize(actor:, invoice: nil, attributes: {})
      @actor = actor
      @invoice = invoice
      @attributes = attributes
    end

    def create
      return unauthorized_invoice unless authorized?

      student = StudentProfile.find_by(id: @attributes[:student_profile_id])
      @attributes[:fee_plan_id] ||= student&.fee_plan_id
      FinanceInvoice.transaction do
        FinanceInvoice.create!(@attributes.merge(created_by: @actor, updated_by: @actor))
      end
    rescue ActiveRecord::RecordInvalid => e
      e.record
    end

    def issue
      return invalid(:forbidden) unless authorized?
      return invalid(:invalid_transition) unless @invoice.draft?
      return invalid(:amount_required) unless @invoice.total_amount.positive?

      FinanceInvoice.transaction { issue! }
      Notifications::InvoiceDelivery.new(actor: @actor, invoice: @invoice).call
      @invoice
    rescue ActiveRecord::RecordInvalid
      invalid(:transition_failed)
    end

    def update
      return invalid(:forbidden) && false unless authorized?
      return invalid(:invalid_transition) && false unless @invoice.draft?

      @invoice.assign_attributes(@attributes.merge(updated_by: @actor))
      @invoice.save
    end

    def cancel
      return invalid(:forbidden) unless authorized?
      return invalid(:invalid_transition) unless @invoice.status.in?(%w[draft issued overdue])
      return invalid(:payments_exist) if @invoice.payments.completed.exists?

      FinanceInvoice.transaction do
        was_issued = !@invoice.draft?
        @invoice.update!(status: "cancelled", updated_by: @actor)
        record_cancellation! if was_issued
      end
      @invoice
    end

    private

    def issue!
      @invoice.update!(status: "issued", issued_on: Date.current, updated_by: @actor)
      Finance::Ledger.record_pair!(source: @invoice, actor: @actor, debit: "accounts_receivable", credit: "revenue",
                                   entry: ledger_attributes("invoice_issued", @invoice.issued_on))
    end

    def authorized? = @actor&.active? && @actor.admin?

    def unauthorized_invoice
      invoice = FinanceInvoice.new(@attributes)
      invoice.errors.add(:base, :forbidden)
      invoice
    end

    def record_cancellation!
      Finance::Ledger.record_pair!(source: @invoice, actor: @actor, debit: "revenue", credit: "accounts_receivable",
                                   entry: ledger_attributes("invoice_cancelled", Date.current))
    end

    def ledger_attributes(entry_type, occurred_on)
      { entry_type:, occurred_on:, currency: @invoice.currency, amount: @invoice.total_amount }
    end

    def invalid(error)
      @invoice.errors.add(:base, error)
      @invoice
    end
  end
end
