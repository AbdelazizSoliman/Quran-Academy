module Admin
  class OperationalReportsController < SchedulingBaseController
    before_action :set_dataset, only: %i[show export]

    def index
      @metrics = OperationalMetrics.new.call
      @report_types = OperationalReports::Dataset::TYPES
    end

    def show; end

    def export
      csv = OperationalReports::CsvExport.new(@dataset).call
      send_data csv, filename: "#{@dataset.title}-#{Date.current}.csv", type: "text/csv; charset=utf-8",
                     disposition: :attachment
    end

    private

    def set_dataset
      @dataset = OperationalReports::Dataset.new(type: params.expect(:report), params:).call
    rescue ArgumentError
      head :not_found
    end
  end
end
