require "rails_helper"

RSpec.describe Admin::AcademySettings::Update do
  let(:setting) { AcademySetting.current }
  let(:actor) { create(:user, :admin) }

  before { AcademySettingEvent.delete_all }

  it "updates, tracks the actor, normalizes arrays, and audits only changed fields" do
    result = described_class.new(
      setting:, actor:,
      attributes: { academy_name: "Updated Academy", supported_locales: ["", "en", "ar", "en"],
                    working_days: %w[monday sunday monday], default_teacher_rate: "250.50" }
    ).call

    expect(result.reload.academy_name).to eq("Updated Academy")
    expect(result.supported_locales).to eq(%w[ar en])
    expect(result.working_days).to eq(%w[sunday monday])
    expect(result.updated_by).to eq(actor)
    expect(result.events.last.metadata.keys).to contain_exactly(
      "academy_name", "working_days", "default_teacher_rate"
    )
  end

  it "creates no event for a no-op update" do
    expect do
      described_class.new(setting:, actor:, attributes: { academy_name: setting.academy_name }).call
    end.not_to change(AcademySettingEvent, :count)
  end

  it "rolls back invalid changes without an event or actor update" do
    result = described_class.new(setting:, actor:, attributes: { academy_name: "" }).call

    expect(result).not_to be_valid
    expect(result.reload.academy_name).to eq("Quran Academy")
    expect(result.updated_by).to be_nil
    expect(AcademySettingEvent.count).to eq(0)
  end

  it "never places secret-like values into metadata" do
    described_class.new(setting:, actor:, attributes: { contact_email: "safe@example.test" }).call

    expect(setting.events.last.metadata.to_s).not_to match(/password|secret|token|credential/i)
  end
end
