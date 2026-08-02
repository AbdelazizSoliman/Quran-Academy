require "rails_helper"

RSpec.describe "Notification services" do
  let(:admin) { create(:user, :admin) }

  it "records a successful Resend delivery attempt" do
    student = create(:student_profile)
    certificate = create(:certificate, student_profile: student,
                                       enrollment: create(:enrollment, student_profile: student))
    provider = instance_double(Notifications::EmailProvider)
    result = Notifications::ProviderResult.new(true, "email-id", { "accepted" => true }, 200, "accepted", nil, nil)
    allow(Notifications::EmailProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(result)
    AcademySetting.current.update!(email_notifications_enabled: true)

    notification = Notifications::Dispatch.new(actor: admin, recipient: student.user, source: certificate,
                                               type: "certificate", channel: "email").call
    expect(notification).to be_sent
    expect(notification.attempt_count).to eq(1)
    expect(notification.attempts.count).to eq(1)
    expect(notification.events.pluck(:event_type)).to eq(%w[created attempted sent])
  end

  it "records provider failures without losing the notification" do
    notification = create(:notification)
    provider = instance_double(Notifications::EmailProvider)
    result = Notifications::ProviderResult.new(false, nil, {}, 503, "failed", "provider_error",
                                               "Email delivery failed")
    allow(Notifications::EmailProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(result)

    Notifications::Attempt.new(notification:, actor: notification.actor).call
    expect(notification).to be_failed
    expect(notification.failure_code).to eq("provider_error")
    expect(notification.attempts.first.http_status).to eq(503)

    success = Notifications::ProviderResult.new(true, "retry-id", { "accepted" => true }, 200,
                                                "accepted", nil, nil)
    allow(provider).to receive(:deliver).and_return(success)
    Notifications::Attempt.new(notification:, actor: notification.actor).call
    expect(notification.attempts.chronological.pluck(:status)).to eq(%w[failed sent])
    expect(notification.retry_count).to eq(1)
  end
  it "resolves profile WhatsApp fallback and normalizes it to E.164" do
    teacher = create(:teacher_profile, whatsapp_number: nil, phone_number: "+20 100-123-4567")
    result = Notifications::RecipientResolver.new(user: teacher.user, channel: "whatsapp").call
    expect(result.address).to eq("+201001234567")
    expect(result.provider_address).to eq("201001234567")
  end

  it "resolves an explicitly requested primary guardian for a minor" do
    student = create(:student_profile, :minor)
    guardian = create(:guardian, whatsapp_number: "+966 50 123 4567", preferred_contact_method: "whatsapp")
    create(:student_guardianship, student_profile: student, guardian:, primary_contact: true)

    result = Notifications::RecipientResolver.new(user: student.user, channel: "whatsapp",
                                                  primary_guardian: true).call
    expect(result.guardian).to eq(guardian)
    expect(result.provider_address).to eq("966501234567")
  end

  it "creates due lesson reminders once for the teacher and enrolled students" do
    now = Time.current
    lesson = create(:scheduled_lesson, :scheduled, starts_at: now + 20.minutes, ends_at: now + 50.minutes)
    participation = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
    participation.enrollment.student_profile.update!(phone_number: "+201001234568")
    configure_reminders
    stub_whatsapp_success

    expect do
      Notifications::LessonReminderScheduler.new(actor: admin, now:).call
    end.to change(Notification, :count).by(2)
    expect do
      Notifications::LessonReminderScheduler.new(actor: admin, now:).call
    end.not_to change(Notification, :count)
  end

  it "creates both due late stages only for pending attendance" do
    now = Time.current
    lesson = create(:scheduled_lesson, :in_progress, starts_at: now - 25.minutes, ends_at: now + 20.minutes)
    participation = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
    participation.enrollment.student_profile.update!(phone_number: "+201001234569")
    create(:lesson_attendance, scheduled_lesson_enrollment: participation, scheduled_lesson: lesson)
    configure_reminders
    stub_whatsapp_success

    expect do
      Notifications::LateAttendanceReminderScheduler.new(actor: admin, now:).call
    end.to change(Notification, :count).by(4)
  end

  def configure_reminders
    AcademySetting.current.update!(lesson_reminders_enabled: true, whatsapp_notifications_enabled: true,
                                   lesson_reminder_minutes_before: 30, first_late_reminder_minutes: 10,
                                   second_late_reminder_minutes: 20)
  end

  def stub_whatsapp_success
    provider = instance_double(Notifications::WhatsAppProvider)
    result = Notifications::ProviderResult.new(true, "wamid.test", { "messages" => [{ "id" => "wamid.test" }] },
                                               200, "accepted", nil, nil)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(result)
  end
end
