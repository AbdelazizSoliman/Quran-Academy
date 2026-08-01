require "csv"

module OperationalReports
  class CsvExport
    UTF8_BOM = "\uFEFF".freeze

    def initialize(dataset)
      @dataset = dataset
    end

    def call
      UTF8_BOM + CSV.generate(force_quotes: true) do |csv|
        csv << @dataset.headers
        @dataset.rows.each { |row| csv << row }
      end
    end
  end
end
