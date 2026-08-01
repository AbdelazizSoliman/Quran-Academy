module Admin
  class LessonReportsController < SchedulingBaseController
    before_action :require_admin!, except: %i[index show]
    before_action :set_report, except: :index

    def index
      @pagy, @reports = pagy(:offset, LessonReportsQuery.new(params:).call, limit: 25)
    end

    def show
      @entries = @report.lesson_student_reports.includes(scheduled_lesson_enrollment: { enrollment: :student_profile })
      @events = @report.events.includes(:actor).recent_first.limit(50)
    end

    def edit; end

    def update
      @report = ::LessonReports::Update.new(actor: current_user, report: @report, attributes: report_params).call
      respond_to_save
    end

    def review = transition(:review)
    def lock = transition(:lock)
    def relock = transition(:relock)

    def reopen
      @report = Admin::LessonReports::Reopen.new(actor: current_user, report: @report,
                                                 reason: params[:reason]).call
      respond_to_save
    end

    private

    def set_report
      @report = LessonReport.includes(:scheduled_lesson, :teacher_profile).find(params.expect(:id))
    end

    def transition(action)
      @report = Admin::LessonReports::Transition.new(actor: current_user, report: @report, action:).call
      respond_to_save
    end

    def report_params
      params.expect(lesson_report: %i[lesson_summary topics_covered general_teacher_notes general_homework
                                      next_lesson_plan overall_engagement overall_progress report_language])
    end

    def respond_to_save
      if @report.errors.empty?
        redirect_to admin_lesson_report_path(@report), notice: t("lesson_reports.messages.updated"), status: :see_other
      else
        redirect_to admin_lesson_report_path(@report), alert: @report.errors.full_messages.to_sentence,
                                                       status: :see_other
      end
    end
  end
end
