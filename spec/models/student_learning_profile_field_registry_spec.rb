require "rails_helper"

RSpec.describe StudentLearningProfileFieldRegistry do
  it "defines fields only for registered sections with type and privacy defaults" do
    described_class::DEFINITIONS.each do |section_key, fields|
      expect(StudentLearningProfileSectionRegistry.keys).to include(section_key)
      fields.each_value do |definition|
        expect(definition.keys).to include(:value_type, :sensitivity, :visibility)
      end
    end
  end

  it "does not register canonical academy source-of-truth fields" do
    forbidden = %w[student_name email phone_number guardian_phone assigned_teacher attendance_percentage
                   assessment_score lesson_history current_quran_level]
    registered = described_class::DEFINITIONS.values.flat_map(&:keys)
    expect(registered & forbidden).to be_empty
  end
end
