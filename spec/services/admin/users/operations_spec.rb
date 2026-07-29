require "rails_helper"

RSpec.describe "Admin user operations" do
  let(:actor) { create(:user, :admin) }

  it "creates and audits users without password metadata" do
    user = Admin::Users::Create.new(
      actor:,
      attributes: attributes_for(:user, :student).merge(preferred_locale: "", password: "SecurePass123!",
                                                        password_confirmation: "SecurePass123!")
    ).call

    expect(user).to be_persisted
    expect(user.preferred_locale).to eq("en")
    expect(user.time_zone).to eq("Cairo")
    expect(user.account_events.last.event_type).to eq("created")
    expect(user.account_events.last.metadata.to_s).not_to include("password")
  end

  it "audits meaningful updates and role changes but not no-op updates" do
    user = create(:user)
    operation = ->(attributes) { Admin::Users::Update.new(actor:, user:, attributes:).call }

    operation.call(first_name: "Changed", role: "teacher")
    count = user.account_events.count
    operation.call(first_name: "Changed", role: "teacher")

    expect(user.reload).to be_teacher
    expect(user.account_events.pluck(:event_type)).to contain_exactly("updated", "role_changed")
    expect(user.account_events.count).to eq(count)
  end

  it "preserves an explicitly selected locale during a role change" do
    user = create(:user, :arabic_locale)

    Admin::Users::Update.new(actor:, user:, attributes: { role: "student" }).call

    expect(user.reload.preferred_locale).to eq("ar")
  end

  it "supports every allowed status transition and audits it" do
    user = create(:user, :pending)
    %i[approve suspend activate disable enable].each do |action|
      Admin::Users::TransitionStatus.new(actor:, user:, action:).call
    end

    expect(user.reload).to be_active
    expect(user.account_events.pluck(:event_type)).to eq(%w[approved suspended activated disabled enabled])
    expect(user.approved_by).to eq(actor)
  end

  it "rejects invalid transitions without an event" do
    user = create(:user, :pending)
    count = UserAccountEvent.count

    expect do
      Admin::Users::TransitionStatus.new(actor:, user:, action: :suspend).call
    end.to raise_error(Admin::Users::Operation::Forbidden)
    expect(UserAccountEvent.count).to eq(count)
  end

  it "prevents self lockout and self demotion" do
    expect do
      Admin::Users::TransitionStatus.new(actor:, user: actor, action: :suspend).call
    end.to raise_error(Admin::Users::Operation::Forbidden)

    expect do
      Admin::Users::Update.new(actor:, user: actor, attributes: { role: "staff" }).call
    end.to raise_error(Admin::Users::Operation::Forbidden)
  end

  it "protects the last active administrator but permits changes with another active admin" do
    actor
    expect do
      Admin::Users::Update.new(actor:, user: actor, attributes: { role: "staff" }).call
    end.to raise_error(Admin::Users::Operation::Forbidden)

    create(:user, :admin)
    other_actor = create(:user, :admin)
    Admin::Users::Update.new(actor: other_actor, user: actor, attributes: { role: "staff" }).call
    expect(actor.reload).to be_staff
  end

  it "resets passwords, increments the session version, and stores no password" do
    user = create(:user, password: "Original123!", password_confirmation: "Original123!")

    result = Admin::Users::ResetPassword.new(
      actor:, user:, password: "Replacement123!", password_confirmation: "Replacement123!"
    ).call

    expect(result.valid_password?("Replacement123!")).to be(true)
    expect(result.valid_password?("Original123!")).to be(false)
    expect(result.session_version).to eq(1)
    expect(result.account_events.last.metadata).to eq({})
  end

  it "rolls back weak password resets without an audit event" do
    user = create(:user)

    expect do
      Admin::Users::ResetPassword.new(actor:, user:, password: "weak", password_confirmation: "weak").call
    end.not_to change(UserAccountEvent, :count)
  end
end
