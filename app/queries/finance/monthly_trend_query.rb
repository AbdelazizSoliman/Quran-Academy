module Finance
  class MonthlyTrendQuery
    Row = Data.define(:month, :collected, :payroll_paid, :expenses, :net_profit)

    def initialize(through: Date.current)
      @through = through.to_date.beginning_of_month
    end

    def call
      summaries = months.index_with { |month| summary_for(month) }
      currencies = summaries.values.flat_map(&:keys).uniq.sort
      currencies.index_with do |currency|
        summaries.map do |month, summary|
          build_row(month, summary.fetch(currency, blank_metrics))
        end
      end
    end

    private

    def months = (0..11).to_a.reverse.map { |offset| @through - offset.months }

    def summary_for(month)
      SummaryQuery.new(params: { from: month, to: month.end_of_month }).call.by_currency
    end

    def build_row(month, metrics)
      Row.new(month:, collected: metrics[:collected], payroll_paid: metrics[:payroll_paid],
              expenses: metrics[:expenses], net_profit: metrics[:net_profit])
    end

    def blank_metrics
      { collected: 0.to_d, payroll_paid: 0.to_d, expenses: 0.to_d, net_profit: 0.to_d }
    end
  end
end
