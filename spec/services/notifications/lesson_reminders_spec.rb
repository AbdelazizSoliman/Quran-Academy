require "rails_helper"

RSpec.describe "Attendance-aware WhatsApp lesson reminders", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) { create(:user, :admin) }
  let(:now) { Time.zone.parse("2026-08-08 09:00:00 UTC") }
  let(:deliveries) { [] }
  let(:provider_result) do
    Notifications::ProviderResult.new(true, "wamid.test", { "messages" => [{ "id" => "wamid.test" }] },
                                      200, "accepted", nil, nil)
  end
  let(:configuration) do
    {
      "WHATSAPP_ENABLED" => "true",
      "WHATSAPP_ACCESS_TOKEN" => "test-access-token",
      "WHATSAPP_PHONE_NUMBER_ID" => "test-phone-id",
      "WHATSAPP_BUSINESS_ACCOUNT_ID" => "test-business-id",
      "WHATSAPP_GRAPH_API_VERSION" => "v23.0",
      "WHATSAPP_LESSON_REMINDER_TEMPLATE" => "quran_lesson_reminder",
      "WHATSAPP_LESSON_REMINDER_LANGUAGE" => "en_US",
      "WHATSAPP_LESSON_JOIN_URL_PREFIX" => "http://example.com/"
    }
  end

  around do |example|
    previous = configuration.keys.index_with { |key| ENV.fetch(key, nil) }
    configuration.each { |key, value| ENV[key] = value }
    travel_to(now) { example.run }
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  before do
    AcademySetting.current.update!(lesson_reminders_enabled: true, whatsapp_notifications_enabled: true,
                                   default_time_zone: "Cairo")
    provider = instance_double(Notifications::WhatsAppProvider)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver) { |**args|
      deliveries << args
      provider_result
    }
  end

  it "sends student and teacher pre-reminders exactly 15 minutes before" do
    lesson, participation = lesson_with_student(starts_at: now + 15.minutes)

    expect { pre_sweep }.to change(Notification, :count).by(2)
    expect(Notification.distinct.pluck(:notification_type)).to eq(["lesson_pre_reminder"])
    expect(Notification.pluck(:recipient_user_id)).to contain_exactly(
      lesson.teacher_profile.user_id, participation.enrollment.student_profile.user_id
    )
  end

  it "does not send a pre-reminder outside the one-minute due window" do
    lesson_with_student(starts_at: now + 15.minutes + 1.second)
    expect { pre_sweep }.not_to change(Notification, :count)
  end

  it "does not duplicate pre-reminders on overlapping scheduler runs" do
    lesson_with_student(starts_at: now + 15.minutes)
    pre_sweep
    expect { pre_sweep }.not_to change(Notification, :count)
  end

  it "sends a late reminder to an absent student" do
    _, participation = lesson_with_student(starts_at: now - 5.minutes, teacher_joined: true)
    create_attendance(participation)

    expect { late_sweep }.to change(Notification, :count).by(1)
    expect(Notification.last.recipient_user).to eq(participation.enrollment.student_profile.user)
  end

  it "skips a student with an authoritative arrival" do
    _lesson, participation = lesson_with_student(starts_at: now - 5.minutes, teacher_joined: true)
    create_attendance(participation, status: "late", arrival_at: now - 30.seconds)
    expect { late_sweep }.not_to change(Notification, :count)
  end

  it "sends a late reminder to a teacher who has not checked in" do
    lesson, participation = lesson_with_student(starts_at: now - 5.minutes)
    create_attendance(participation, status: "present", arrival_at: now - 1.minute)

    expect { late_sweep }.to change(Notification, :count).by(1)
    expect(Notification.last.recipient_user).to eq(lesson.teacher_profile.user)
  end

  it "skips a teacher who has checked in" do
    lesson, participation = lesson_with_student(starts_at: now - 5.minutes, teacher_joined: true)
    create_attendance(participation)
    late_sweep
    expect(Notification.pluck(:recipient_user_id)).not_to include(lesson.teacher_profile.user_id)
  end

  it "sends two independent late reminders when both parties are absent" do
    lesson_with_student(starts_at: now - 5.minutes)
    expect { late_sweep }.to change(Notification, :count).by(2)
    expect(Notification.distinct.pluck(:notification_type)).to eq(["lesson_late_reminder"])
  end

  it "sends no late reminders when both parties have joined" do
    _lesson, participation = lesson_with_student(starts_at: now - 5.minutes, teacher_joined: true)
    create_attendance(participation, status: "present", arrival_at: now - 1.minute)
    expect { late_sweep }.not_to change(Notification, :count)
  end

  it "checks presence when a queued late sweep actually executes" do
    _lesson, participation = lesson_with_student(starts_at: now - 5.minutes, teacher_joined: true)
    attendance = create_attendance(participation)
    attendance.update!(status: "present", arrival_at: now - 1.minute)

    expect { LateReminderSweepJob.perform_now(actor: admin, now: now + 2.minutes) }.not_to change(Notification, :count)
  end

  it "catches up an absent participant when a queued sweep executes late" do
    lesson_with_student(starts_at: now - 5.minutes, teacher_joined: true)
    expect do
      LateReminderSweepJob.perform_now(actor: admin, now: now + 2.minutes)
    end.to change(Notification, :count).by(1)
  end

  it "uses the selected numbers and exact Meta template parameter order" do
    lesson, participation = lesson_with_student(starts_at: now + 15.minutes)
    participation.enrollment.student_profile.update!(whatsapp_number: "+20 111-222-3344")
    lesson.teacher_profile.update!(whatsapp_number: "+20 122-333-4455")
    pre_sweep

    student_delivery = deliveries.find { |item| item[:recipient] == "201112223344" }
    teacher_delivery = deliveries.find { |item| item[:recipient] == "201223334455" }
    expect(student_delivery.dig(:template, :name)).to eq("quran_lesson_reminder")
    expected_body = [participation.enrollment.student_profile.user.full_name, "August 08, 2026", "12:15",
                     "Teacher", lesson.teacher_profile.display_name, "Your lesson starts in 15 minutes."]
    expect(body_texts(student_delivery)).to eq(expected_body)
    expect(body_texts(teacher_delivery).last).to eq("Your lesson starts in 15 minutes.")
    student_suffix = student_delivery.dig(:template, :components, 1, :parameters, 0, :text)
    teacher_suffix = teacher_delivery.dig(:template, :components, 1, :parameters, 0, :text)
    expect(student_suffix).to eq("student/schedule/#{lesson.id}/join")
    expect(teacher_suffix).to eq("teacher/schedule/#{lesson.id}/join")
  end

  %w[en en_US].each do |language|
    it "accepts #{language} for lesson reminders and passes it to Meta" do
      ENV["WHATSAPP_LESSON_REMINDER_LANGUAGE"] = language
      lesson_with_student(starts_at: now + 15.minutes)

      expect(Notifications::WhatsappConfiguration).to be_lesson_reminders_configured
      pre_sweep
      expect(deliveries).not_to be_empty
      expect(deliveries).to all(include(template: hash_including(language_code: language)))
    end
  end

  it "uses the late context in the same template" do
    lesson_with_student(starts_at: now - 5.minutes)
    late_sweep
    expect(deliveries).to all(satisfy do |delivery|
      body_texts(delivery).last == "Your lesson started 5 minutes ago. Please join now."
    end)
  end

  it "keeps the internal join route in WhatsApp when the teacher supplies the meeting URL" do
    lesson, = lesson_with_student(starts_at: now + 15.minutes)
    external_url = "https://meet.example.test/teacher-private"
    lesson.teacher_profile.update!(online_meeting_url: external_url)
    lesson.update_column(:online_meeting_url, nil) # rubocop:disable Rails/SkipsModelValidations -- inherited URL

    pre_sweep

    expect(deliveries).not_to be_empty
    deliveries.each do |delivery|
      suffix = delivery.dig(:template, :components, 1, :parameters, 0, :text)
      expect(suffix).to match(%r{\A(?:student|teacher)/schedule/#{lesson.id}/join\z})
      expect(delivery.to_s).not_to include(external_url)
    end
  end

  it "sends normal reminders for a recurring-schedule occurrence" do
    lesson, participation = lesson_with_student(starts_at: now + 15.minutes)
    schedule = create(:enrollment_lesson_schedule, enrollment: participation.enrollment,
                                                   teacher_profile: lesson.teacher_profile,
                                                   starts_on: lesson.starts_at.to_date)
    slot = create(:enrollment_lesson_schedule_slot, enrollment_lesson_schedule: schedule,
                                                    weekday: lesson.starts_at.strftime("%A").downcase,
                                                    starts_at_local: lesson.starts_at.strftime("%H:%M"))
    lesson.update!(enrollment_lesson_schedule_slot: slot, recurrence_date: lesson.starts_at.to_date)

    pre_sweep

    expect(deliveries).not_to be_empty
    expect(Notification.where(source: lesson, notification_type: "lesson_pre_reminder")).to exist
  end

  it "safely skips a missing external meeting URL" do
    lesson, = lesson_with_student(starts_at: now + 15.minutes)
    lesson.update_column(:online_meeting_url, nil) # rubocop:disable Rails/SkipsModelValidations -- corrupt data
    expect { pre_sweep }.not_to change(Notification, :count)
    expect(deliveries).to be_empty
  end

  it "skips a student late reminder after the student uses the internal join route" do
    lesson, participation = lesson_with_student(starts_at: now - 5.minutes, teacher_joined: true)
    sign_in participation.enrollment.student_profile.user
    get join_student_schedule_path(lesson)
    expect { late_sweep }.not_to change(Notification, :count)
  end

  it "skips a teacher late reminder after the teacher uses the internal join route" do
    lesson, participation = lesson_with_student(starts_at: now - 5.minutes)
    create_attendance(participation, status: "present", arrival_at: now - 1.minute)
    sign_in lesson.teacher_profile.user
    get join_teacher_schedule_path(lesson)
    expect { late_sweep }.not_to change(Notification, :count)
  end

  it "safely skips when WhatsApp is disabled at the environment kill switch" do
    ENV["WHATSAPP_ENABLED"] = "false"
    lesson_with_student(starts_at: now + 15.minutes)
    expect { pre_sweep }.not_to change(Notification, :count)
  end

  it "skips recipients whose contact preference excludes WhatsApp" do
    lesson, participation = lesson_with_student(starts_at: now + 15.minutes)
    lesson.teacher_profile.update!(notification_method: "email")
    participation.enrollment.student_profile.update!(preferred_contact_method: "email")
    expect { pre_sweep }.not_to change(Notification, :count)
  end

  it "skips an invalid WhatsApp number without calling Meta" do
    lesson, participation = lesson_with_student(starts_at: now + 15.minutes)
    lesson.teacher_profile.update!(notification_method: "email")
    participation.enrollment.student_profile.update!(whatsapp_number: "invalid", phone_number: nil)
    expect { pre_sweep }.not_to change(Notification, :count)
    expect(deliveries).to be_empty
  end

  it "audits a Meta provider failure without changing attendance" do
    failure = Notifications::ProviderResult.new(false, nil, {}, 500, "failed", "provider_error", "rejected")
    provider = instance_double(Notifications::WhatsAppProvider, deliver: failure)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    lesson, participation = lesson_with_student(starts_at: now - 5.minutes, teacher_joined: true)
    attendance = create_attendance(participation)

    late_sweep
    notification = Notification.last
    expect(notification).to be_failed
    expect(notification.attempts.last.http_status).to eq(500)
    expect(notification.events.pluck(:event_type)).to eq(%w[created attempted failed])
    expect(attendance.reload).to be_pending
    expect(lesson.reload).to be_scheduled
  end

  it "audits a Meta 4xx rejection" do
    failure = Notifications::ProviderResult.new(false, nil, {}, 400, "failed", "template_error", "rejected")
    notification = dispatch_failed_late_reminder(failure)
    expect(notification).to be_failed
    expect(notification.attempts.last.http_status).to eq(400)
  end

  it "audits a Meta timeout without inventing an HTTP status" do
    failure = Notifications::ProviderResult.new(false, nil, {}, nil, "failed", "Timeout::Error",
                                                "WhatsApp delivery failed")
    notification = dispatch_failed_late_reminder(failure)
    expect(notification).to be_failed
    expect(notification.attempts.last.error_code).to eq("Timeout::Error")
    expect(notification.attempts.last.http_status).to be_nil
  end

  private

  def lesson_with_student(starts_at:, teacher_joined: false, join_url: "https://meet.example.test/lesson/abc123")
    teacher_status = teacher_joined ? "on_time" : "not_checked_in"
    lesson = create(:scheduled_lesson, :scheduled, starts_at:, ends_at: starts_at + 45.minutes,
                                                   academy_time_zone: "Cairo", online_meeting_url: join_url,
                                                   teacher_checked_in_at: teacher_joined ? now - 1.minute : nil,
                                                   teacher_attendance_status: teacher_status)
    participation = create(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
    participation.enrollment.student_profile.update!(preferred_contact_method: "whatsapp",
                                                     whatsapp_number: "+201001234568")
    [lesson, participation]
  end

  def create_attendance(participation, status: "pending", arrival_at: nil)
    create(:lesson_attendance, scheduled_lesson_enrollment: participation,
                               scheduled_lesson: participation.scheduled_lesson, status:, arrival_at:)
  end

  def pre_sweep = Notifications::LessonReminderScheduler.new(actor: admin, now:).call
  def late_sweep = Notifications::LateAttendanceReminderScheduler.new(actor: admin, now:).call

  def body_texts(delivery)
    delivery.dig(:template, :components, 0, :parameters).map { |parameter| parameter[:text] }
  end

  def dispatch_failed_late_reminder(failure)
    provider = instance_double(Notifications::WhatsAppProvider, deliver: failure)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    _lesson, participation = lesson_with_student(starts_at: now - 5.minutes, teacher_joined: true)
    create_attendance(participation)
    late_sweep
    Notification.last
  end
end
