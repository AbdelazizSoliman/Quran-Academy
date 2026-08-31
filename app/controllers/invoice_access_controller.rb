class InvoiceAccessController < ApplicationController
  before_action :set_invoice

  def show; end

  def print
    render "shared/invoices/print", layout: "print"
  end

  private

  def set_invoice
    @invoice = FinanceInvoice.find_signed!(params.expect(:token), purpose: :invoice_access)
    raise ActiveRecord::RecordNotFound unless allowed?
    raise ActiveRecord::RecordNotFound if @invoice.status.in?(%w[draft cancelled])
  end

  def allowed?
    return false unless current_user&.active?

    current_user.admin? || billed_student? || linked_guardian?
  end

  def billed_student? = current_user.student_profile&.id == @invoice.student_profile_id

  def linked_guardian?
    guardian = current_user.guardian_profile
    guardian && guardian.student_guardianships.active.exists?(student_profile_id: @invoice.student_profile_id)
  end
end
