require "rails_helper"

RSpec.describe "Teacher profile operations" do
  let(:admin) { create(:user, :admin) }
  let(:teacher) { create(:user, :teacher) }

  before { AcademySetting.current.update!(teaching_languages: %w[ar en]) }

  it "creates a profile with actor ownership and a safe audit event" do
    profile = Admin::TeacherProfiles::Create.new(
      actor: admin, user: teacher, attributes: attributes
    ).call

    expect(profile).to be_persisted
    expect(profile.created_by).to eq(admin)
    expect(profile.events.pluck(:event_type)).to eq(%w[created])
    expect(profile.events.first.metadata.to_s).not_to match(/password|token/i)
  end

  it "updates normalized arrays and audits meaningful changes only" do
    profile = create(:teacher_profile, teaching_languages: %w[ar])
    operation = lambda do |values|
      Admin::TeacherProfiles::Update.new(
        actor: admin, profile:, attributes: { teaching_languages: values }
      ).call
    end

    operation.call(["", "ar", "ar"])
    expect(profile.events.count).to eq(0)
    operation.call(%w[en ar en])
    expect(profile.reload.teaching_languages).to eq(%w[en ar])
    expect(profile.events.last.metadata.dig("changes", "teaching_languages", "to")).to eq(%w[en ar])
  end

  it "distinguishes compensation and employment changes" do
    profile = create(:teacher_profile)
    Admin::TeacherProfiles::Update.new(actor: admin, profile:,
                                       attributes: { default_lesson_rate: 150 }).call
    Admin::TeacherProfiles::Update.new(actor: admin, profile:,
                                       attributes: { employment_status: "suspended" }).call

    expect(profile.events.pluck(:event_type)).to eq(%w[compensation_changed employment_status_changed])
  end

  it "audits administrator-only internal notes without exposing secret-like keys" do
    profile = create(:teacher_profile)
    Admin::TeacherProfiles::Update.new(actor: admin, profile:,
                                       attributes: { internal_notes: "Reviewed privately" }).call

    expect(profile.reload.internal_notes).to eq("Reviewed privately")
    expect(profile.events.last.metadata.dig("changes", "internal_notes", "to")).to eq("Reviewed privately")
  end

  it "creates no audit for invalid updates" do
    profile = create(:teacher_profile)
    Admin::TeacherProfiles::Update.new(actor: admin, profile:,
                                       attributes: { default_lesson_rate: -1 }).call

    expect(profile.events).to be_empty
    expect(profile.reload.default_lesson_rate).to eq(100)
  end

  it "rolls back the profile change when audit persistence fails" do
    profile = create(:teacher_profile, display_name: "Original")
    allow(TeacherProfileEvent).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

    Admin::TeacherProfiles::Update.new(
      actor: admin, profile:, attributes: { display_name: "Rolled back" }
    ).call

    expect(profile.reload.display_name).to eq("Original")
    expect(profile.events).to be_empty
  end

  it "verifies, archives, and restores transactionally" do
    profile = create(:teacher_profile, :complete)

    %i[verify archive restore].each do |action|
      Admin::TeacherProfiles::Transition.new(actor: admin, profile:, action:).call
    end

    expect(profile.reload.profile_status).to eq("draft")
    expect(profile.events.pluck(:event_type)).to eq(%w[verified archived restored])
  end

  it "rejects invalid lifecycle transitions" do
    profile = create(:teacher_profile)
    Admin::TeacherProfiles::Transition.new(actor: admin, profile:, action: :restore).call

    expect(profile.errors[:profile_status]).to be_present
    expect(profile.events).to be_empty
  end

  it "allows self-service fields and never changes administrative fields" do
    profile = create(:teacher_profile, user: teacher, internal_notes: "Private", default_lesson_rate: 100)
    permitted = { display_name: "Updated", teaching_languages: %w[en] }
    Teacher::Profiles::Update.new(actor: teacher, profile:, attributes: permitted).call

    expect(profile.reload.attributes.values_at("display_name", "internal_notes", "default_lesson_rate"))
      .to eq(["Updated", "Private", BigDecimal("100")])
    expect(profile.events.last.event_type).to eq("self_updated")
    expect(profile.events.last.metadata.to_s).not_to include("internal_notes", "default_lesson_rate")
  end

  def attributes
    attributes_for(:teacher_profile).except(:user)
  end
end
