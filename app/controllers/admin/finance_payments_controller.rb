module Admin
  class FinancePaymentsController < BaseController
    before_action :set_invoice

    def create
      payment = Finance::RecordPayment.new(actor: current_user, invoice: @invoice,
                                           attributes: payment_params).call
      if payment.persisted?
        redirect_to admin_finance_invoice_path(@invoice), notice: t("finance.messages.payment_recorded"),
                                                          status: :see_other
      else
        redirect_to admin_finance_invoice_path(@invoice), alert: payment.errors.full_messages.to_sentence,
                                                          status: :see_other
      end
    end

    def refund
      payment = @invoice.payments.find(params.expect(:id))
      Finance::RecordPayment.new(actor: current_user, invoice: @invoice).refund(payment)
      respond_to_refund(payment)
    end

    private

    def set_invoice = @invoice = FinanceInvoice.find(params.expect(:finance_invoice_id))

    def payment_params
      params.expect(finance_payment: %i[amount received_on payment_method reference notes])
    end

    def respond_to_refund(payment)
      message = if payment.errors.empty?
                  { notice: t("finance.messages.payment_refunded") }
                else
                  { alert: payment.errors.full_messages.to_sentence }
                end
      redirect_to admin_finance_invoice_path(@invoice), **message, status: :see_other
    end
  end
end
