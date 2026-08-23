module Admin
  class WhatsappConversationsController < BaseController
    before_action :set_conversation, only: %i[show archive reopen]

    def index
      scope = WhatsappConversation.includes(:contact).recent_first
      status = params.fetch(:status, nil)
      scope = scope.where(status:) if status.in?(WhatsappConversation::STATUSES)
      scope = scope.unread if params[:unread] == "1"
      @pagy, @conversations = pagy(:offset, scope, limit: 25)
    end

    def show
      @conversation.mark_read!
      @messages = @conversation.messages.chronological
    end

    def archive
      @conversation.update!(status: "archived")
      redirect_to admin_whatsapp_conversation_path(@conversation),
                  notice: t("whatsapp_inbox.messages.archived"), status: :see_other
    end

    def reopen
      @conversation.update!(status: "open")
      redirect_to admin_whatsapp_conversation_path(@conversation),
                  notice: t("whatsapp_inbox.messages.reopened"), status: :see_other
    end

    private

    def set_conversation
      @conversation = WhatsappConversation.find(params.expect(:id))
    end
  end
end
