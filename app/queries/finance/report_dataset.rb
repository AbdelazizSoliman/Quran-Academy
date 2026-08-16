module Finance
  ReportResult = Data.define(:title, :headers, :rows)

  class ReportDataset
    TYPES = %w[revenue receivables payroll expenses student_statements ledger].freeze

    def initialize(type:, params: {})
      @type = type.to_s
      @params = params
    end

    def call
      raise ArgumentError, "unknown report" unless @type.in?(TYPES)

      method(@type).call
    end

    private

    def revenue
      rows = FinancePayment.includes(finance_invoice: { student_profile: :user }).completed
                           .where(received_on: date_range).map { |payment| revenue_row(payment) }
      result(%w[payment invoice student received_on method currency amount], rows)
    end

    def receivables
      rows = FinanceInvoice.includes(student_profile: :user).outstanding.where(due_on: date_range).map do |invoice|
        [invoice.public_id, invoice.student_profile.user.full_name, invoice.due_on, invoice.effective_status,
         invoice.currency, invoice.total_amount, invoice.paid_amount, invoice.balance_due]
      end
      result(%w[invoice student due_on status currency total paid balance], rows)
    end

    def payroll
      rows = TeacherPayroll.includes(teacher_profile: :user).where(period_starts_on: date_range).map do |item|
        [item.public_id, item.teacher_profile.user.full_name, item.period_starts_on, item.period_ends_on,
         item.status, item.currency, item.net_amount]
      end
      result(%w[payroll teacher starts_on ends_on status currency amount], rows)
    end

    def expenses
      rows = FinanceExpense.where(incurred_on: date_range).recent_first.pluck(
        :public_id, :category, :vendor, :description, :incurred_on, :status, :currency, :amount
      )
      result(%w[expense category vendor description incurred_on status currency amount], rows)
    end

    def student_statements
      scope = FinanceInvoice.includes(student_profile: :user).where(due_on: date_range)
      scope = scope.where(student_profile_id: @params[:student_id]) if @params[:student_id].present?
      rows = scope.map { |invoice| student_statement_row(invoice) }
      result(%w[student invoice due_on status currency total paid balance], rows)
    end

    def ledger
      rows = FinanceLedgerEntry.where(occurred_on: date_range).recent_first.pluck(
        :public_id, :occurred_on, :entry_type, :account, :direction, :currency, :amount, :source_type, :source_id
      )
      result(%w[entry occurred_on type account direction currency amount source_type source_id], rows)
    end

    def revenue_row(payment)
      invoice = payment.finance_invoice
      [payment.public_id, invoice.public_id, invoice.student_profile.user.full_name, payment.received_on,
       payment.payment_method, payment.currency, payment.amount]
    end

    def student_statement_row(invoice)
      [invoice.student_profile.user.full_name, invoice.public_id, invoice.due_on, invoice.effective_status,
       invoice.currency, invoice.total_amount, invoice.paid_amount, invoice.balance_due]
    end

    def date_range
      from = parse_date(@params[:from]) || Date.current.beginning_of_month
      to = parse_date(@params[:to]) || Date.current.end_of_month
      from..to
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def result(headers, rows) = ReportResult.new(@type, headers, rows)
  end
end
