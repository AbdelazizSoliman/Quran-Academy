require "rails_helper"

RSpec.describe "Academic progress queries" do
  it "defaults admin assessments to a finite date range and allowlisted sort" do
    current = create(:student_assessment, assessment_date: Date.current)
    create(:student_assessment, assessment_date: 2.years.ago)
    result = Admin::StudentAssessmentsQuery.new(params: { sort: "unsafe SQL" }).call
    expect(result).to contain_exactly(current)
  end

  it "isolates teacher assessments" do
    teacher = create(:teacher_profile)
    own = create(:student_assessment, teacher_profile: teacher)
    create(:student_assessment)
    expect(Teacher::StudentAssessmentsQuery.new(teacher_profile: teacher, params: {}).call).to contain_exactly(own)
  end

  it "shows students only published personal academic records" do
    student = create(:student_profile)
    published = create(:student_assessment, student_profile: student,
                                            enrollment: create(:enrollment, student_profile: student), status: "published")
    create(:student_assessment, student_profile: student,
                                enrollment: create(:enrollment, student_profile: student), status: "draft")
    expect(Student::AcademicRecordsQuery.new(student_profile: student).assessments).to contain_exactly(published)
  end
end
