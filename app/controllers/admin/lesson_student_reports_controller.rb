module Admin
  class LessonStudentReportsController < SchedulingBaseController
    before_action :require_admin!
    before_action :set_entry

    def edit; end

    def update
      @entry = ::LessonStudentReports::Update.new(actor: current_user, entry: @entry,
                                                  attributes: entry_params).call
      if @entry.errors.empty?
        redirect_to admin_lesson_report_path(@entry.lesson_report), notice: t("lesson_reports.messages.updated"),
                                                                    status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_entry
      report = LessonReport.find(params.expect(:lesson_report_id))
      @entry = report.lesson_student_reports.find(params.expect(:id))
    end

    def entry_params
      permitted = ::LessonStudentReports::Update::FIELDS.map(&:to_sym)
      params.expect(lesson_student_report: permitted + [{ tajweed_topics: [] }])
    end
  end
end
