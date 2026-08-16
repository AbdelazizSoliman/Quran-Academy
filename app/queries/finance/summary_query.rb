module Finance
  class SummaryQuery
    Summary = Data.define(:from, :to, :by_currency)

    def initialize(params: {})
      @from = parse_date(params[:from]) || Date.current.beginning_of_month
      @to = parse_date(params[:to]) || Date.current.end_of_month
    end

    def call
      values = Hash.new { |hash, currency| hash[currency] = blank_metrics }
      metric_totals.each { |metric, totals| add(values, metric, totals) }
      calculate_profit(values)
      Summary.new(from: @from, to: @to, by_currency: values.sort.to_h)
    end

    private

    def invoices
      FinanceInvoice.where(status: %w[issued partially_paid paid overdue], issued_on: @from..@to)
    end

    def payments = FinancePayment.completed.where(received_on: @from..@to)
    def payrolls = TeacherPayroll.where(period_starts_on: @from..@to)
    def paid_payrolls = TeacherPayroll.where(status: "paid", paid_at: @from.beginning_of_day..@to.end_of_day)
    def expenses = FinanceExpense.where(status: "paid", paid_at: @from.beginning_of_day..@to.end_of_day)

    def metric_totals
      {
        invoiced: invoices.group(:currency).sum(:total_amount),
        collected: payments.group(:currency).sum(:amount),
        outstanding: outstanding_totals,
        payroll_due: payrolls.where(status: "approved").group(:currency).sum(:net_amount),
        payroll_paid: paid_payrolls.group(:currency).sum(:net_amount),
        expenses: expenses.group(:currency).sum(:amount)
      }
    end

    def outstanding_totals
      FinanceInvoice.outstanding.includes(:payments).each_with_object(Hash.new(0.to_d)) do |invoice, totals|
        totals[invoice.currency] += invoice.balance_due
      end
    end

    def blank_metrics
      { invoiced: 0.to_d, collected: 0.to_d, outstanding: 0.to_d, payroll_due: 0.to_d,
        payroll_paid: 0.to_d, expenses: 0.to_d, net_profit: 0.to_d }
    end

    def add(values, metric, totals)
      totals.each { |currency, amount| values[currency][metric] = amount.to_d }
    end

    def calculate_profit(values)
      values.each_value do |metrics|
        metrics[:net_profit] = metrics[:collected] - metrics[:payroll_paid] - metrics[:expenses]
      end
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
  end
end
