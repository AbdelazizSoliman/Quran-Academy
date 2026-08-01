module Admin
  class CommunicationLogsController < SchedulingBaseController
    include ManualCommunicationRedirect

    before_action :require_admin!, except: %i[index show]
    before_action :set_log, except: :index

    def index
      @pagy, @logs = pagy(:offset, CommunicationLogsQuery.new(params:).call, limit: 25)
    end

    def show
      @events = @log.events.includes(:actor).order(created_at: :desc)
    end

    def mark_opened
      transition(:mark_opened)
      redirect_to_external_communication(@log)
    end

    def confirm_sent = transition(:confirm_sent)
    def cancel = transition(:cancel)

    private

    def set_log
      @log = CommunicationLog.find(params.expect(:id))
    end

    def transition(action)
      @log = ManualCommunications::Transition.new(actor: current_user, log: @log, action:).call
      return @log if action == :mark_opened

      redirect_to admin_communication_log_path(@log), notice: t("communications.messages.updated"),
                                                      status: :see_other
    end
  end
end
