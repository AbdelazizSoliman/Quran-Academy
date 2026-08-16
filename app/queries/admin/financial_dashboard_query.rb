module Admin
  class FinancialDashboardQuery
    Result = Data.define(:month, :active_students, :students_without_pricing, :revenue_by_currency,
                         :payroll_by_currency, :profit_by_currency, :approved_payrolls,
                         :fee_plan_breakdown)
    RevenueSummary = Struct.new(:revenue, :missing_pricing, :plan_totals)

    def initialize(month: nil)
      @month = parse_month(month)
    end

    def call
      students = StudentProfile.includes(:fee_plan).where(learning_status: "active")
      summary = summarize_revenue(students)
      payrolls = payroll_scope
      payroll = sum_by_currency(payrolls)

      build_result(students, summary, payrolls, payroll)
    end

    private

    def summarize_revenue(students)
      summary = RevenueSummary.new(Hash.new(0.to_d), 0, plan_totals_hash)
      students.find_each { |student| add_student_revenue(summary, student) }
      summary
    end

    def add_student_revenue(summary, student)
      amount = estimated_monthly_revenue(student)
      return summary.missing_pricing += 1 unless amount

      key = [student.fee_plan&.name || I18n.t("financial_dashboard.custom_pricing"), student.billing_currency]
      summary.revenue[student.billing_currency] += amount
      summary.plan_totals[key][:students] += 1
      summary.plan_totals[key][:amount] += amount
    end

    def plan_totals_hash
      Hash.new { |hash, key| hash[key] = { students: 0, amount: 0.to_d } }
    end

    def build_result(students, summary, payrolls, payroll)
      Result.new(
        month: @month,
        active_students: students.count,
        students_without_pricing: summary.missing_pricing,
        revenue_by_currency: summary.revenue.sort.to_h,
        payroll_by_currency: payroll.sort.to_h,
        profit_by_currency: profits(summary.revenue, payroll),
        approved_payrolls: payrolls.where(status: "approved").count,
        fee_plan_breakdown: fee_plan_breakdown(summary.plan_totals)
      )
    end

    def profits(revenue, payroll)
      (revenue.keys | payroll.keys).sort.index_with do |currency|
        revenue.fetch(currency, 0.to_d) - payroll.fetch(currency, 0.to_d)
      end
    end

    def fee_plan_breakdown(plan_totals)
      rows = plan_totals.map do |(name, currency), values|
        values.merge(name:, currency:)
      end
      rows.sort_by { |row| [-row[:amount], row[:name]] }
    end

    def parse_month(value)
      return Date.current.beginning_of_month if value.blank?

      Date.strptime(value.to_s, "%Y-%m").beginning_of_month
    rescue Date::Error
      Date.current.beginning_of_month
    end

    def estimated_monthly_revenue(student)
      amount = if student.weekly_price.positive?
                 student.weekly_price * 52 / 12
               else
                 fee_plan_monthly_amount(student)
               end
      return if amount.nil?

      (amount * (100 - student.discount_percentage) / 100).round(2)
    end

    def fee_plan_monthly_amount(student)
      plan = student.fee_plan
      return if plan.nil?

      case plan.billing_cycle
      when "monthly" then plan.amount
      when "weekly" then plan.amount * 52 / 12
      when "per_lesson"
        sessions = student.sessions_per_month || monthly_sessions(student.weekly_lesson_count)
        plan.amount * sessions if sessions
      end
    end

    def monthly_sessions(weekly_count)
      (weekly_count * 52.to_d / 12).round if weekly_count
    end

    def payroll_scope
      TeacherPayroll.where.not(status: "cancelled")
                    .where("period_starts_on <= ? AND period_ends_on >= ?", @month.end_of_month, @month)
    end

    def sum_by_currency(scope)
      scope.group(:currency).sum(:net_amount).transform_values(&:to_d)
    end
  end
end
