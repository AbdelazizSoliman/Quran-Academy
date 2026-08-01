module Teacher
  class LessonStudentReportsController < ApplicationController
    before_action :require_teacher!
    before_action :set_entry

    def edit; end

    def update
      @entry = ::LessonStudentReports::Update.new(actor: current_user, entry: @entry,
                                                  attributes: entry_params).call
      if @entry.errors.empty?
        redirect_to teacher_schedule_report_path(@lesson), notice: t("lesson_reports.messages.updated"),
                                                           status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_entry
      @lesson = current_user.teacher_profile.scheduled_lessons.find(params.expect(:schedule_id))
      @entry = @lesson.lesson_report.lesson_student_reports.find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def entry_params
      permitted = ::LessonStudentReports::Update::FIELDS.map(&:to_sym)
      params.expect(lesson_student_report: permitted + [{ tajweed_topics: [] }])
    end

    def require_teacher!
      return if current_user&.active? && current_user.teacher?

      render plain: t("authorization.forbidden"), status: :forbidden
    end
  end
end
