module Teacher
  class ExamSessionsController < BaseController
    before_action -> { require_release_feature!(:exams) }
    def index
      @exam_sessions = scope.includes(:program, :course_offering).chronological
    end

    def show
      @exam = scope.find(params.expect(:id))
    end

    def complete
      @exam = scope.find(params.expect(:id))
      ExamSessions::Transition.new(actor: current_user, exam_session: @exam, action: :complete).call
      redirect_to teacher_exam_path(@exam), notice: t("academic.messages.saved")
    end

    private

    def scope = ExamSession.where(teacher_profile: current_user.teacher_profile)
  end
end
