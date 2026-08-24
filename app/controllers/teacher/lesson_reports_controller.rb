module Teacher
  class LessonReportsController < ApplicationController
    before_action :require_teacher!
    before_action :set_lesson
    before_action :set_report, except: :show

    def show
      @report = ::LessonReports::Initialize.new(actor: current_user, lesson: @lesson).call
      if @report.errors.any?
        return redirect_to teacher_schedule_path(@lesson),
                           alert: @report.errors.full_messages.to_sentence
      end

      load_student_records
    end

    def edit; end

    def update
      @report = ::LessonReports::Update.new(actor: current_user, report: @report, attributes: report_params).call
      respond_to_save
    end

    def submit
      @report = ::LessonReports::Submit.new(actor: current_user, report: @report).call
      respond_to_save
    end

    private

    def load_student_records
      @entries = @report.lesson_student_reports.includes(
        scheduled_lesson_enrollment: [:student_profile, { enrollment: :student_profile }]
      )
      @assessments_by_student_id = StudentAssessment.where(teacher_profile: current_user.teacher_profile,
                                                           scheduled_lesson: @lesson)
                                                    .index_by(&:student_profile_id)
    end

    def set_lesson
      @lesson = current_user.teacher_profile.scheduled_lessons.find(params.expect(:schedule_id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def set_report
      @report = @lesson.lesson_report || ::LessonReports::Initialize.new(actor: current_user, lesson: @lesson).call
    end

    def report_params
      params.expect(lesson_report: %i[lesson_summary topics_covered general_teacher_notes general_homework
                                      next_lesson_plan overall_engagement overall_progress report_language])
    end

    def respond_to_save
      if @report.errors.empty?
        redirect_to teacher_schedule_report_path(@lesson), notice: t("lesson_reports.messages.updated"),
                                                           status: :see_other
      else
        redirect_to teacher_schedule_report_path(@lesson), alert: @report.errors.full_messages.to_sentence,
                                                           status: :see_other
      end
    end

    def require_teacher!
      return if current_user&.active? && current_user.teacher?

      render plain: t("authorization.forbidden"), status: :forbidden
    end
  end
end
