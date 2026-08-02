module Admin
  class AcademicDashboardController < SchedulingBaseController
    def show
      published = StudentAssessment.where(status: "published")
      @metrics = {
        assessments: StudentAssessment.count,
        published: published.count,
        average_score: published.average(:overall_score)&.round(2),
        pass_rate: pass_rate(published),
        exams: ExamSession.count,
        certificates: Certificate.count,
        needs_attention: StudentProgress.where(trend: "needs_attention").count
      }
      @top_students = StudentProgress.includes(student_profile: :user).where.not(average_score: nil)
                                     .order(average_score: :desc).limit(5)
      @attention_students = StudentProgress.includes(student_profile: :user)
                                           .where(trend: "needs_attention").limit(10)
    end

    private

    def pass_rate(scope)
      total = scope.where.not(overall_score: nil).count
      return 0 if total.zero?

      passing_score = AcademySetting.current.assessment_grade_boundaries.fetch("D", 60).to_d
      (scope.where(overall_score: passing_score..).count * 100.0 / total).round(1)
    end
  end
end
