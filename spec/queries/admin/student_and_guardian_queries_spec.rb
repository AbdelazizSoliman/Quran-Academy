require "rails_helper"

RSpec.describe "Student and guardian admin queries" do
  it "searches students by identity and guardian without duplicate rows" do
    student = create(:student_profile, display_name: "Amina Learner")
    guardian = create(:guardian, full_name: "Fatima Parent")
    create(:student_guardianship, student_profile: student, guardian:)
    expect(Admin::StudentsQuery.new(params: { q: "Fatima" }).call).to contain_exactly(student)
    expect(Admin::StudentsQuery.new(params: { sort: "DROP TABLE users" }).call).to include(student)
  end

  it "filters missing guardians and guardian records by linked student" do
    missing = create(:student_profile)
    linked = create(:student_profile)
    guardian = create(:guardian)
    create(:student_guardianship, student_profile: linked, guardian:)
    results = Admin::StudentsQuery.new(params: { guardian: "missing" }).call
    expect(results).to include(missing)
    expect(results).not_to include(linked)
    expect(Admin::GuardiansQuery.new(params: { q: linked.public_id }).call).to contain_exactly(guardian)
  end
end
