require "rails_helper"

RSpec.describe Notifications::InvoiceOverdueReminderScheduler do
  let(:admin) { create(:user, :admin) }
  let(:student) { create(:student_profile, :complete) }
  let(:today) { Date.new(2026, 8, 16) }

  before do
    AcademySetting.current.update!(payment_notifications_enabled: true, payment_whatsapp_enabled: true,
                                   email_notifications_enabled: true, whatsapp_notifications_enabled: true)
    stub_email_success
    stub_whatsapp_success
  end

  def generate(today: self.today) = described_class.new(actor: admin, today:).call

  def invoice(due_on:, status: "issued")
    create(:finance_invoice, status:, student_profile: student, due_on:, created_by: admin, updated_by: admin)
  end

  it "reminds the payer by email and whatsapp the day after an invoice becomes overdue" do
    invoice(due_on: today - 1.day)

    expect { generate }.to change(Notification, :count).by(2)
    expect(Notification.pluck(:channel)).to contain_exactly("email", "whatsapp")
    expect(Notification.distinct.pluck(:notification_type)).to eq(["invoice_overdue"])
  end

  it "does not remind on or before the due date" do
    invoice(due_on: today)

    expect { generate }.not_to change(Notification, :count)
  end

  it "is idempotent within the same day and reminds again after the repeat interval" do
    invoice(due_on: today - 1.day)
    generate

    expect { generate }.not_to change(Notification, :count)
    expect { generate(today: today + 6.days) }.not_to change(Notification, :count)
    expect { generate(today: today + 7.days) }.to change(Notification, :count).by(2)
  end

  it "stops once the invoice is paid" do
    invoice(due_on: today - 1.day, status: "paid")

    expect { generate }.not_to change(Notification, :count)
  end

  it "does nothing when payment notifications are disabled" do
    AcademySetting.current.update!(payment_notifications_enabled: false)
    invoice(due_on: today - 1.day)

    expect { generate }.not_to change(Notification, :count)
  end

  def stub_email_success
    provider = instance_double(Notifications::EmailProvider)
    result = Notifications::ProviderResult.new(true, "email-id", { "accepted" => true }, 200, "accepted", nil, nil)
    allow(Notifications::EmailProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(result)
  end

  def stub_whatsapp_success
    provider = instance_double(Notifications::WhatsAppProvider)
    result = Notifications::ProviderResult.new(true, "wamid.test", { "messages" => [{ "id" => "wamid.test" }] },
                                               200, "accepted", nil, nil)
    allow(Notifications::WhatsAppProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:deliver).and_return(result)
  end
end
