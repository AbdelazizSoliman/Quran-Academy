class AccountInvitationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_session_version!
  skip_after_action :remember_session_version
  before_action :set_invitation
  layout "authentication"

  def edit
    return if performed?

    expire_if_needed
  end

  def update
    return if performed?

    accept_invitation
    if @invitation.accepted?
      redirect_to account_invitation_success_path(locale: I18n.locale), notice: t("invitations.accepted.notice")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def success; end

  private

  def set_invitation
    return if action_name == "success"

    @invitation = AccountInvitation.includes(:user).find_by(token_digest: AccountInvitations::Token.digest(params[:token]))
    render :invalid, status: :not_found unless @invitation
  end

  def expire_if_needed
    return unless @invitation&.expires_at&.past? && !@invitation.accepted? && !@invitation.cancelled?

    AccountInvitations::Accept.new(invitation: @invitation, password: nil, password_confirmation: nil,
                                   ip: request.remote_ip, user_agent: request.user_agent).call
  end

  def password_params
    params.expect(account_invitation: %i[password password_confirmation])
  end

  def accept_invitation
    AccountInvitations::Accept.new(
      invitation: @invitation, password: password_params[:password],
      password_confirmation: password_params[:password_confirmation],
      ip: request.remote_ip, user_agent: request.user_agent
    ).call
  end
end
