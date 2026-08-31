module Admin
  class FinanceInvoicesController < BaseController
    before_action :set_invoice, only: %i[show edit update issue cancel deliver print]

    def index
      scope = FinanceInvoice.includes(student_profile: :user).recent_first
      scope = scope.where(status: params[:status]) if FinanceInvoice::STATUSES.include?(params[:status])
      @pagy, @invoices = pagy(:offset, scope, limit: 25)
    end

    def show
      @payments = @invoice.payments.recent_first
      @payment = @invoice.payments.new(received_on: Date.current, payment_method: "bank_transfer")
    end

    def new
      @invoice = FinanceInvoice.new(default_attributes)
      @students = student_options
    end

    def edit
      unless @invoice.draft?
        return redirect_to(admin_finance_invoice_path(@invoice), alert: t("finance.messages.draft_only"))
      end

      @students = student_options
    end

    def create
      @invoice = Finance::InvoiceOperation.new(actor: current_user, attributes: invoice_params).create
      if @invoice.persisted?
        return redirect_to(admin_finance_invoice_path(@invoice),
                           notice: t("finance.messages.created"))
      end

      @students = student_options
      render :new, status: :unprocessable_content
    end

    def update
      unless @invoice.draft?
        return redirect_to(admin_finance_invoice_path(@invoice), alert: t("finance.messages.draft_only"))
      end

      if Finance::InvoiceOperation.new(actor: current_user, invoice: @invoice, attributes: invoice_params).update
        redirect_to admin_finance_invoice_path(@invoice), notice: t("finance.messages.updated")
      else
        @students = student_options
        render :edit, status: :unprocessable_content
      end
    end

    def issue = transition(:issue)
    def cancel = transition(:cancel)

    def deliver
      notifications = Notifications::InvoiceDelivery.new(actor: current_user, invoice: @invoice).call
      if notifications.any?(&:persisted?)
        redirect_to admin_finance_invoice_path(@invoice), notice: t("finance.messages.delivered"), status: :see_other
      else
        redirect_to admin_finance_invoice_path(@invoice), alert: t("finance.messages.delivery_failed"),
                                                          status: :see_other
      end
    end

    def print
      render "shared/invoices/print", layout: "print"
    end

    private

    def set_invoice = @invoice = FinanceInvoice.find(params.expect(:id))

    def invoice_params
      params.expect(finance_invoice: %i[student_profile_id fee_plan_id billing_period_starts_on
                                        billing_period_ends_on due_on currency subtotal discount_amount
                                        tax_amount notes])
    end

    def default_attributes
      { billing_period_starts_on: Date.current.beginning_of_month,
        billing_period_ends_on: Date.current.end_of_month, due_on: Date.current + 7.days,
        currency: AcademySetting.current.billing_currency }
    end

    def student_options
      StudentProfile.includes(:user).where.not(learning_status: %w[departed inactive]).recent_first
    end

    def transition(action)
      Finance::InvoiceOperation.new(actor: current_user, invoice: @invoice).public_send(action)
      if @invoice.errors.empty?
        redirect_to admin_finance_invoice_path(@invoice), notice: t("finance.messages.updated"), status: :see_other
      else
        redirect_to admin_finance_invoice_path(@invoice), alert: @invoice.errors.full_messages.to_sentence,
                                                          status: :see_other
      end
    end
  end
end
