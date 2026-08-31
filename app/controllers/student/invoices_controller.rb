module Student
  class InvoicesController < BaseController
    before_action :set_invoice, only: %i[show print]

    def index = @invoices = invoice_scope.recent_first
    def show; end
    def print = render("shared/invoices/print", layout: "print")

    private

    def invoice_scope
      FinanceInvoice.where(student_profile_id: current_user.student_profile&.id).where.not(status: %w[draft cancelled])
    end

    def set_invoice = @invoice = invoice_scope.find(params.expect(:id))
  end
end
