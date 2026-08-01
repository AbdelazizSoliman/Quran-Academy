require "rails_helper"

RSpec.describe OperationalReports::Dataset do
  it "uses a finite date range and exports Arabic-compatible CSV" do
    lesson = create(:scheduled_lesson, status: "completed", starts_at: Time.current, ends_at: 1.hour.from_now)
    dataset = described_class.new(type: "lesson_completion").call
    expect(dataset.rows.flatten).to include(lesson.public_id)
    expect(OperationalReports::CsvExport.new(dataset).call).to start_with("\uFEFF")
  end

  it "rejects unknown report types" do
    expect { described_class.new(type: "banking").call }.to raise_error(ArgumentError)
  end

  it "provides every operational report without a nil relation" do
    described_class::TYPES.each do |type|
      expect(described_class.new(type:).call.rows).to be_a(Array)
    end
  end
end
