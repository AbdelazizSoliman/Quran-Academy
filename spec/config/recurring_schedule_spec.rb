require "rails_helper"

RSpec.describe "Solid Queue recurring schedule" do
  let(:configuration) { YAML.safe_load_file(Rails.root.join("config/recurring.yml")) }
  let(:production) { configuration.fetch("production") }

  it "defines the production reminder and recurrence schedules" do
    expect(production).to eq(
      "lesson_reminder_sweep" => { "class" => "ReminderSweepJob", "schedule" => "* * * * *" },
      "late_lesson_reminder_sweep" => { "class" => "LateReminderSweepJob", "schedule" => "* * * * *" },
      "recurring_lesson_generation" => {
        "class" => "RecurringLessonGenerationJob", "schedule" => "10 0 * * * UTC"
      }
    )
  end

  it "has the recurring execution uniqueness required by Solid Queue" do
    index = ActiveRecord::Base.connection.indexes(:solid_queue_recurring_executions)
                              .find { |candidate| candidate.columns == %w[task_key run_at] }
    expect(index.unique).to be(true)
  end
end
