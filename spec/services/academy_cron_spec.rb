require "rails_helper"

RSpec.describe AcademyCron do
  let(:now) { Time.zone.parse("2026-08-16 00:10:00 UTC") }
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
  let(:notification_actor) { create(:user, :admin) }
  let(:scheduling_actor) { create(:user, :admin) }
  let(:pre_sweep) { instance_double(Notifications::LessonReminderScheduler, call: []) }
  let(:late_sweep) { instance_double(Notifications::LateAttendanceReminderScheduler, call: []) }
  let(:generation) { instance_double(EnrollmentLessonSchedules::GenerationSweep, call: []) }

  before do
    allow(connection).to receive(:select_value).and_return(true)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("NOTIFICATION_ACTOR_ID").and_return(notification_actor.id.to_s)
    allow(ENV).to receive(:fetch).with("SCHEDULING_ACTOR_ID").and_return(scheduling_actor.id.to_s)
    allow(Notifications::LessonReminderScheduler).to receive(:new).and_return(pre_sweep)
    allow(Notifications::LateAttendanceReminderScheduler).to receive(:new).and_return(late_sweep)
    allow(EnrollmentLessonSchedules::GenerationSweep).to receive(:new).and_return(generation)
  end

  it "runs both sweeps and the daily generation once after its UTC due time" do
    expect(described_class.new(now:, connection:).call).to be(true)
    expect(pre_sweep).to have_received(:call)
    expect(late_sweep).to have_received(:call)
    expect(generation).to have_received(:call).once
    expect(CronRun.find_by!(task_name: "recurring_lesson_generation", run_on: now.to_date)).to be_completed_at

    described_class.new(now: now + 5.minutes, connection:).call
    expect(generation).to have_received(:call).once
  end

  it "skips all work when another cron execution owns the lock" do
    allow(connection).to receive(:select_value).and_return(false)
    expect(described_class.new(now:, connection:).call).to be(false)
    expect(pre_sweep).not_to have_received(:call)
  end

  it "does not run daily generation before 00:10 UTC" do
    described_class.new(now: now - 1.minute, connection:).call
    expect(generation).not_to have_received(:call)
  end

  it "removes the daily claim after failure so a later cron can retry" do
    allow(generation).to receive(:call).and_raise("failed")
    described_class.new(now:, connection:).call
    expect(CronRun.where(task_name: "recurring_lesson_generation", run_on: now.to_date)).not_to exist
  end
end
