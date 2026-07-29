require "rails_helper"

RSpec.describe "Guardian and relationship operations" do
  let(:admin) { create(:user, :admin) }

  it "creates, updates, archives, and audits a guardian" do
    guardian = Admin::Guardians::Create.new(actor: admin, attributes: attributes_for(:guardian)).call
    expect(guardian.events.pluck(:event_type)).to eq(["created"])
    Admin::Guardians::Update.new(actor: admin, guardian:, attributes: { phone_number: "+4420" }).call
    expect(guardian.events.last.event_type).to eq("contact_information_changed")
    Admin::Guardians::Transition.new(actor: admin, guardian:, action: :archive).call
    expect(guardian.reload).to be_archived
  end

  it "switches the primary guardian transactionally and audits the change" do
    student = create(:student_profile, :minor)
    first = Admin::StudentGuardianships::Create.new(
      actor: admin, student_profile: student, guardian: create(:guardian),
      attributes: { relationship_type: "father", primary_contact: true }
    ).call
    second = Admin::StudentGuardianships::Create.new(
      actor: admin, student_profile: student, guardian: create(:guardian),
      attributes: { relationship_type: "mother" }
    ).call
    Admin::StudentGuardianships::Transition.new(actor: admin, guardianship: second, action: :make_primary).call
    expect(first.reload).not_to be_primary_contact
    expect(second.reload).to be_primary_contact
    expect(second.events.last.event_type).to eq("made_primary")
  end

  it "requires a replacement before ending the primary relationship of a verified minor" do
    student = create(:student_profile, :minor)
    link = create(:student_guardianship, student_profile: student, primary_contact: true,
                                         emergency_contact: true, legal_guardian: true)
    student.update!(profile_status: "verified")
    result = Admin::StudentGuardianships::Transition.new(actor: admin, guardianship: link, action: :end).call
    expect(result.errors).to be_present
    expect(link.reload).to be_active
  end

  it "creates and attaches a guardian atomically" do
    student = create(:student_profile, :minor)
    operation = Admin::StudentGuardianships::CreateGuardianAndAttach.new(
      actor: admin, student_profile: student, guardian_attributes: attributes_for(:guardian),
      relationship_attributes: { relationship_type: "mother" }
    ).call
    expect(operation).to be_success
    expect(operation.guardian.events.pluck(:event_type)).to eq(["created"])
    expect(operation.guardianship.events.pluck(:event_type)).to eq(["created"])
  end

  it "rolls back a newly created guardian when attachment fails" do
    student = create(:student_profile)
    expect do
      Admin::StudentGuardianships::CreateGuardianAndAttach.new(
        actor: admin, student_profile: student, guardian_attributes: attributes_for(:guardian),
        relationship_attributes: { relationship_type: "unsupported" }
      ).call
    end.not_to change(Guardian, :count)
  end
end
