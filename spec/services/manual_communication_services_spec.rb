require "rails_helper"

RSpec.describe "Manual communication services" do
  let(:lesson) do
    create(:scheduled_lesson, status: "completed", completed_at: Time.current, attendance_status: "locked")
  end
  let(:teacher) { lesson.teacher_profile.user }
  let(:participant) { create(:scheduled_lesson_enrollment, scheduled_lesson: lesson) }
  let(:report) do
    create(:lesson_report, scheduled_lesson: lesson, teacher_profile: lesson.teacher_profile,
                           lesson_summary: "Safe summary", general_homework: "Revise page 3")
  end
  let(:entry) do
    create(:lesson_student_report, lesson_report: report, scheduled_lesson_enrollment: participant,
                                   status: "completed", homework: "Read page 4", next_lesson_target: "Page 5",
                                   private_teacher_notes: "PRIVATE SECRET")
  end

  it "normalizes international phone formats without country assumptions" do
    expect(ManualCommunications::PhoneNormalizer.call("+44 (20) 1234-5678").digits).to eq("442012345678")
    expect(ManualCommunications::PhoneNormalizer.call("123")).not_to be_valid
  end

  it "builds an English student WhatsApp URL and excludes private notes" do
    entry.student_profile.update!(whatsapp_number: "+44 20 1234 5678")
    result = builder(channel: "whatsapp", locale: "en").call
    expect(result.external_url).to start_with("https://wa.me/442012345678?text=")
    expect(result.body).to include("Safe summary", "Read page 4")
    expect(result.body).not_to include("PRIVATE SECRET")
  end

  it "builds a fully Arabic message" do
    result = builder(channel: "email", locale: "ar").call
    expect(result.body).to include("تحديث تقدم")
    expect(result.body).not_to include("Progress update")
  end

  it "builds URL-encoded mailto preparation" do
    result = builder(channel: "email", locale: "en").call
    expect(result.external_url).to start_with("mailto:")
    expect(result.external_url).to include("subject=")
  end

  it "returns a structured error for missing WhatsApp details" do
    entry.student_profile.update!(whatsapp_number: nil)
    expect(builder(channel: "whatsapp", locale: "en").call).not_to be_valid
  end

  it "prepares a log without claiming delivery" do
    log = ManualCommunications::Prepare.new(actor: teacher, entry:, channel: "email",
                                            template_type: "student_progress",
                                            recipient: entry.student_profile.user).call
    expect(log).to be_prepared
    expect(log.confirmed_sent_at).to be_nil
  end

  it "marks opened separately and confirms manually idempotently" do
    log = ManualCommunications::Prepare.new(actor: teacher, entry:, channel: "email",
                                            template_type: "student_progress",
                                            recipient: entry.student_profile.user).call
    ManualCommunications::Transition.new(actor: teacher, log:, action: :mark_opened).call
    expect(log).to be_opened
    ManualCommunications::Transition.new(actor: teacher, log:, action: :confirm_sent).call
    expect(log).to be_confirmed_sent
    expect do
      ManualCommunications::Transition.new(actor: teacher, log:, action: :confirm_sent).call
    end.not_to change(CommunicationLogEvent, :count)
  end

  private

  def builder(channel:, locale:)
    ManualCommunications::MessageBuilder.new(channel:, template_type: "student_progress", entry:,
                                             recipient: entry.student_profile.user, locale:)
  end
end
