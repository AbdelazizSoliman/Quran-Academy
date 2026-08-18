module Notifications
  class InvoiceOverdueReminderScheduler
    REPEAT_INTERVAL_DAYS = 7
    CHANNELS = %w[email whatsapp].freeze

    def initialize(actor:, today: Date.current)
      @actor = actor
      @today = today
      @setting = AcademySetting.current
    end

    def call
      return [] unless enabled?

      due_invoices.flat_map { |invoice| notify_invoice(invoice) }
    end

    private

    def enabled? = @setting.payment_notifications_enabled?

    def due_invoices
      FinanceInvoice.outstanding.where(due_on: ...@today).select { |invoice| due_today?(invoice) }
    end

    def due_today?(invoice)
      days = days_overdue(invoice)
      days.positive? && ((days - 1) % REPEAT_INTERVAL_DAYS).zero?
    end

    def days_overdue(invoice) = (@today - invoice.due_on).to_i

    def notify_invoice(invoice)
      recipient = invoice.student_profile&.user
      return [] unless recipient

      CHANNELS.filter_map { |channel| dispatch(invoice, recipient, channel) }
    end

    def dispatch(invoice, recipient, channel)
      Dispatch.new(actor: @actor, recipient:, source: invoice, type: "invoice_overdue", channel:,
                   idempotency_key: idempotency_key(invoice, channel)).call
    end

    def idempotency_key(invoice, channel)
      "invoice-overdue:invoice:#{invoice.id}:channel:#{channel}:day:#{days_overdue(invoice)}"
    end
  end
end
