module Teacher
  class CommunicationLogsController < ApplicationController
    include ManualCommunicationRedirect

    before_action :require_teacher!
    before_action :set_log

    def show; end

    def mark_opened
      transition(:mark_opened)
      return redirect_to_external_communication(@log) if @log.errors.empty?

      redirect_to teacher_communication_log_path(@log), alert: @log.errors.full_messages.to_sentence
    end

    def confirm_sent = transition(:confirm_sent)
    def cancel = transition(:cancel)

    private

    def set_log
      @log = current_user.communication_logs.find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def transition(action)
      @log = ManualCommunications::Transition.new(actor: current_user, log: @log, action:).call
      return @log if action == :mark_opened

      redirect_to teacher_communication_log_path(@log), notice: t("communications.messages.updated"), status: :see_other
    end

    def require_teacher!
      return if current_user&.active? && current_user.teacher?

      render plain: t("authorization.forbidden"), status: :forbidden
    end
  end
end
