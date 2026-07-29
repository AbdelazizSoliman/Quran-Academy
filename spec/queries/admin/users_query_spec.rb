require "rails_helper"

RSpec.describe Admin::UsersQuery do
  let!(:arabic_admin) { create(:user, :admin, first_name: "Ahmed", last_name: "Ali", email: "ahmed@example.test") }
  let!(:english_student) { create(:user, :student, :pending, first_name: "Mary", email: "mary@example.test") }

  it "searches names, full names, and email case-insensitively" do
    expect(described_class.new(params: { query: "ahmed ali" }).call).to contain_exactly(arabic_admin)
    expect(described_class.new(params: { query: "MARY@" }).call).to contain_exactly(english_student)
  end

  it "filters supported role, status, and locale values" do
    result = described_class.new(params: { role: "student", status: "pending", preferred_locale: "en" }).call

    expect(result).to contain_exactly(english_student)
  end

  it "ignores invalid filters and uses only allowlisted sorting" do
    injection = "created_at; DROP TABLE users"
    result = described_class.new(params: { role: injection, sort: injection, direction: "sideways" }).call

    expect(result.to_a).to contain_exactly(arabic_admin, english_student)
    expect(User.table_exists?).to be(true)
  end

  it "sorts deterministically by an allowed field" do
    expect(described_class.new(params: { sort: "email", direction: "asc" }).call.first).to eq(arabic_admin)
  end
end
