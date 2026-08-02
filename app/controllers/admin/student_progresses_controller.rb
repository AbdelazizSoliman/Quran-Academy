module Admin
  class StudentProgressesController < SchedulingBaseController
    before_action :require_admin!, only: :update
    before_action :set_progress, except: :index

    def index
      scope = StudentProgress.includes(student_profile: :user).order(average_score: :desc, id: :asc)
      @pagy, @progresses = pagy(:offset, scope, limit: 25)
    end

    def show
      load_history
    end

    def load_history
      @assessments = StudentAssessment.where(student_profile: @progress.student_profile)
                                      .includes(:assessment_template).recent_first.limit(20)
      @certificates = @progress.student_profile.certificates.recent_first
    end

    def update
      @progress.update!(progress_params.merge(updated_by: current_user))
      redirect_to admin_student_progress_path(@progress), notice: t("academic.messages.saved")
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      load_history
      render :show, status: :unprocessable_content
    end

    private

    def set_progress = @progress = StudentProgress.find(params.expect(:id))

    def progress_params
      params.expect(student_progress: %i[current_surah current_page current_ayah memorization_progress
                                          revision_progress completion_percentage ijazah_ready lock_version])
    end
  end
end
