module Teacher
  class CommunicationsController < ApplicationController
    before_action :require_teacher!

    def create
      log = prepare(entry)
      redirect_to teacher_communication_log_path(log), notice: t("communications.messages.prepared"), status: :see_other
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def entry
      lesson = current_user.teacher_profile.scheduled_lessons.find(params.expect(:schedule_id))
      lesson.lesson_report.lesson_student_reports.find(params.expect(:entry_id))
    end

    def prepare(report_entry)
      ManualCommunications::Prepare.new(actor: current_user, entry: report_entry,
                                        recipient: report_entry.student_profile.user,
                                        channel: params[:channel], template_type: params[:template_type],
                                        locale: params[:locale]).call
    end

    def require_teacher!
      return if current_user&.active? && current_user.teacher?

      render plain: t("authorization.forbidden"), status: :forbidden
    end
  end
end
