module Admin
  class FinanceExpensesController < BaseController
    before_action :set_expense, only: %i[show approve pay cancel]

    def index
      scope = FinanceExpense.recent_first
      scope = scope.where(status: params[:status]) if FinanceExpense::STATUSES.include?(params[:status])
      @pagy, @expenses = pagy(:offset, scope, limit: 25)
    end

    def show; end

    def new
      @expense = FinanceExpense.new(incurred_on: Date.current, currency: AcademySetting.current.billing_currency,
                                    payment_method: "bank_transfer")
    end

    def create
      @expense = Finance::ExpenseOperation.new(actor: current_user, attributes: expense_params).create
      if @expense.persisted?
        return redirect_to(admin_finance_expense_path(@expense),
                           notice: t("finance.messages.created"))
      end

      render :new, status: :unprocessable_content
    end

    def approve = transition(:approve)
    def pay = transition(:pay)
    def cancel = transition(:cancel)

    private

    def set_expense = @expense = FinanceExpense.find(params.expect(:id))

    def expense_params
      params.expect(finance_expense: %i[category vendor description amount currency incurred_on payment_method
                                        reference])
    end

    def transition(action)
      Finance::ExpenseOperation.new(actor: current_user, expense: @expense).transition(action)
      redirect_to admin_finance_expense_path(@expense),
                  **(if @expense.errors.empty?
                       { notice: t("finance.messages.updated") }
                     else
                       { alert: @expense.errors.full_messages.to_sentence }
                     end), status: :see_other
    end
  end
end
