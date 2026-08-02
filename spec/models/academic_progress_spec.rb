require "rails_helper"

RSpec.describe "Academic progress models" do
  it "generates immutable public identifiers" do
    records = [create(:assessment_template), create(:assessment_category), create(:student_assessment),
               create(:exam_session), create(:certificate)]

    expect(records.map(&:public_id)).to all(match(/\A(?:ATP|ACG|ASM|EXM|CER)-[A-Z0-9]{10}\z/))
    expect { records.first.update!(public_id: "ATP-AAAAAAAAAA") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
  end

  it "enforces controlled lifecycle and catalog values" do
    expect(StudentAssessment::STATUSES).to eq(%w[draft submitted reviewed published archived])
    expect(ExamSession::STATUSES).to eq(%w[draft scheduled completed reviewed published archived])
    expect(Certificate::TYPES).to eq(%w[program_completion exam_completion ijazah])
    expect(AssessmentCategory::CODES).to include("memorization", "tajweed", "behavior")
  end

  it "validates assessment ownership consistency" do
    assessment = build(:student_assessment, student_profile: create(:student_profile))
    expect(assessment).not_to be_valid
  end

  it "validates rubric score bounds and types" do
    score = build(:assessment_score, numeric_score: 101)
    expect(score).not_to be_valid
  end

  it "creates certificate verification identifiers and QR placeholders" do
    certificate = create(:certificate)
    expect(certificate.verification_code).to match(/\AVFY-[A-Z0-9]{12}\z/)
    expect(certificate.qr_placeholder).to eq(certificate.verification_code)
  end
end
