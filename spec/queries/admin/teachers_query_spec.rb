require "rails_helper"

RSpec.describe Admin::TeachersQuery do
  before { AcademySetting.current.update!(teaching_languages: %w[ar en]) }

  let!(:arabic_teacher) do
    create(:teacher_profile, display_name: "Amina Teacher", phone_number: "+20111",
                             teaching_languages: %w[ar], teaching_specializations: %w[tajweed],
                             student_age_groups: %w[children], employment_status: "active",
                             user: create(:user, :teacher, email: "amina@example.test"))
  end
  let!(:english_teacher) do
    create(:teacher_profile, display_name: "Bilal Mentor", whatsapp_number: "+44222",
                             teaching_languages: %w[en], teaching_specializations: %w[revision],
                             student_age_groups: %w[adults], engagement_type: "volunteer",
                             profile_status: "archived",
                             user: create(:user, :teacher, email: "bilal@example.test"))
  end

  it "searches public ID, display name, email, phone, and WhatsApp" do
    [arabic_teacher.public_id, "Amina", "bilal@example", "+20111", "+44222"].each do |term|
      expect(described_class.new(params: { q: term }).call).not_to be_empty
    end
  end

  it "applies scalar and multi-value filters without duplicates" do
    expect(result(employment_status: "active")).to eq([arabic_teacher])
    expect(result(engagement_type: "volunteer")).to eq([english_teacher])
    expect(result(profile_status: "archived")).to eq([english_teacher])
    expect(result(teaching_language: "ar")).to eq([arabic_teacher])
    expect(result(specialization: "revision")).to eq([english_teacher])
    expect(result(age_group: "children")).to eq([arabic_teacher])
  end

  it "uses allowlisted sorting and safely falls back for invalid input" do
    expect(result(sort: "name", direction: "asc")).to eq([arabic_teacher, english_teacher])
    expect { result(sort: "created_at; DROP TABLE users", direction: "sideways") }.not_to raise_error
  end

  def result(params)
    described_class.new(params:).call.to_a
  end
end
