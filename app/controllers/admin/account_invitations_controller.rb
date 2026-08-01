module Admin
  class AccountInvitationsController < BaseController
    before_action :set_invitation, except: :index

    def index
      @pagy, @invitations = pagy(:offset, AccountInvitationsQuery.new(params:).call, limit: 20)
    end

    def show
      @events = @invitation.events.includes(:actor).order(created_at: :desc)
    end

    def resend
      result = AccountInvitations::Resend.new(invitation: @invitation, actor: current_user).call
      redirect_after(result.invitation.errors.empty?, "resent")
    end

    def cancel
      AccountInvitations::Cancel.new(invitation: @invitation, actor: current_user).call
      redirect_after(@invitation.errors.empty?, "cancelled")
    end

    private

    def set_invitation = @invitation = AccountInvitation.find(params.expect(:id))

    def redirect_after(success, message)
      if success
        redirect_to admin_account_invitation_path(@invitation), notice: t("invitations.admin.#{message}")
      else
        redirect_to admin_account_invitation_path(@invitation), alert: @invitation.errors.full_messages.to_sentence
      end
    end
  end
end
