module Teacher
  class AcademicDashboardsController < BaseController
    def show
      assessments = StudentAssessment.where(teacher_profile: current_user.teacher_profile)
      @metrics = { assigned: assessments.count, drafts: assessments.where(status: "draft").count,
                   submitted: assessments.where(status: "submitted").count,
                   upcoming_exams: ExamSession.where(teacher_profile: current_user.teacher_profile,
                                                     status: "scheduled", starts_at: Time.current..).count }
      student_ids = assessments.select(:student_profile_id)
      @attention_students = StudentProgress.includes(student_profile: :user)
                                           .where(student_profile_id: student_ids, trend: "needs_attention").limit(10)
    end
  end
end
