require "rails_helper"

RSpec.describe "Notification jobs" do
  let(:actor) { create(:user, :admin) }

  it "delegates the lesson reminder sweep to the existing service" do
    now = Time.current
    service = instance_double(Notifications::LessonReminderScheduler, call: [])
    allow(Notifications::LessonReminderScheduler).to receive(:new).with(actor:, now:).and_return(service)

    ReminderSweepJob.perform_now(actor:, now:)
    expect(service).to have_received(:call)
  end

  it "delegates the late reminder sweep to the existing service" do
    now = Time.current
    service = instance_double(Notifications::LateAttendanceReminderScheduler, call: [])
    allow(Notifications::LateAttendanceReminderScheduler).to receive(:new)
      .with(actor:, now:).and_return(service)

    LateReminderSweepJob.perform_now(actor:, now:)
    expect(service).to have_received(:call)
  end

  it "delegates individual delivery to the existing dispatch service" do
    recipient = create(:user, :student)
    source = create(:scheduled_lesson, :scheduled)
    service = instance_double(Notifications::Dispatch, call: build(:notification))
    allow(Notifications::Dispatch).to receive(:new)
      .with(actor:, recipient:, source:, type: "lesson_reminder", channel: "whatsapp").and_return(service)

    NotificationDispatchJob.perform_now(actor:, recipient:, source:, notification_type: "lesson_reminder",
                                        channel: "whatsapp")
    expect(service).to have_received(:call)
  end
end
