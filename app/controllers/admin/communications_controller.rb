module Admin
  class CommunicationsController < SchedulingBaseController
    before_action :require_admin!

    def create
      report = LessonReport.find(params.expect(:lesson_report_id))
      entry = report.lesson_student_reports.find(params.expect(:entry_id))
      log = prepare(entry)
      redirect_to admin_communication_log_path(log),
                  **(if log.errors.empty?
                       { notice: t("communications.messages.prepared") }
                     else
                       { alert: log.errors.full_messages.to_sentence }
                     end), status: :see_other
    end

    private

    def prepare(entry)
      ManualCommunications::Prepare.new(actor: current_user, entry:, channel: params[:channel],
                                        template_type: params[:template_type], recipient: recipient(entry),
                                        locale: params[:locale]).call
    end

    def recipient(entry)
      return entry.student_profile.user unless params[:recipient_type] == "guardian"

      entry.student_profile.student_guardianships.active.find_by(primary_contact: true)&.guardian
    end
  end
end
