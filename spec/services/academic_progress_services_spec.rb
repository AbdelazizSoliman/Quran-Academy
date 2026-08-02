require "rails_helper"

RSpec.describe "Academic progress services" do
  let(:admin) { create(:user, :admin) }

  it "initializes rubric scores transactionally" do
    template = create(:assessment_template)
    create_list(:assessment_rubric_item, 2, assessment_template: template)
    enrollment = create(:enrollment, :active)
    teacher = create(:teacher_profile, :active)

    assessment = StudentAssessments::Create.new(
      actor: admin, attributes: { enrollment:, teacher_profile: teacher, assessment_template: template,
                                  assessment_date: Date.current }
    ).call
    expect(assessment.scores.count).to eq(2)
    expect(assessment.events.pluck(:event_type)).to eq(["created"])
  end

  it "calculates weighted percentages and letter grades" do
    assessment = create(:student_assessment)
    first = create(:assessment_rubric_item, assessment_template: assessment.assessment_template, weight: 3)
    second = create(:assessment_rubric_item, assessment_template: assessment.assessment_template, weight: 1)
    result = Assessments::GradeCalculator.new(
      scores: [build(:assessment_score, student_assessment: assessment, assessment_rubric_item: first,
                                        numeric_score: 100),
               build(:assessment_score, student_assessment: assessment, assessment_rubric_item: second,
                                        numeric_score: 60)]
    ).call
    expect(result).to eq(percentage: 90.to_d, letter_grade: "A")
  end

  it "requires completed scores before submission and enforces admin review/publish" do
    assessment = create(:student_assessment)
    create(:assessment_rubric_item, assessment_template: assessment.assessment_template)
    assessment.scores.create!(assessment_rubric_item: assessment.assessment_template.rubric_items.first)

    StudentAssessments::Transition.new(actor: admin, assessment:, action: :submit).call
    expect(assessment.errors).to be_present
  end

  it "recalculates published student summary and trend" do
    student = create(:student_profile)
    create(:student_assessment, student_profile: student, enrollment: create(:enrollment, student_profile: student),
                                status: "published", overall_score: 85, assessment_date: 1.month.ago)
    create(:student_assessment, student_profile: student, enrollment: create(:enrollment, student_profile: student),
                                status: "published", overall_score: 92, assessment_date: Date.current)
    progress = StudentProgresses::Recalculate.new(student_profile: student, actor: admin).call
    expect(progress.average_score).to eq(88.5)
    expect(progress.trend).to eq("improving")
  end

  it "audits exam transitions and certificate issuance" do
    program = create(:program)
    exam = ExamSessions::Create.new(actor: admin, attributes: attributes_for(:exam_session).merge(
      program:, course_offering: create(:course_offering, program:), teacher_profile: create(:teacher_profile)
    )).call
    student = create(:student_profile)
    certificate = Certificates::Issue.new(actor: admin, attributes: attributes_for(:certificate).merge(
      student_profile: student, enrollment: create(:enrollment, student_profile: student)
    )).call
    expect(exam.events.pluck(:event_type)).to eq(["created"])
    expect(certificate.events.pluck(:event_type)).to eq(["created"])
  end
end
