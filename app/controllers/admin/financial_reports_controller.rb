module Admin
  class FinancialReportsController < BaseController
    before_action :set_dataset, only: %i[show export]

    def index
      @summary = Finance::SummaryQuery.new(params:).call
      @monthly_trends = Finance::MonthlyTrendQuery.new(through: @summary.to).call
      @report_types = Finance::ReportDataset::TYPES
    end

    def show; end

    def export
      csv = OperationalReports::CsvExport.new(@dataset).call
      send_data csv, filename: "#{@dataset.title}-#{Date.current}.csv", type: "text/csv; charset=utf-8",
                     disposition: :attachment
    end

    private

    def set_dataset
      @dataset = Finance::ReportDataset.new(type: params.expect(:report), params:).call
    rescue ArgumentError
      head :not_found
    end
  end
end
