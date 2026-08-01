class AccountInvitationMailer < ApplicationMailer
  def invitation_email
    @invitation = params[:invitation]
    @user = @invitation.user
    @academy = AcademySetting.current
    @invitation_url = edit_account_invitation_url(token: params[:token], locale: @user.preferred_locale)
    I18n.with_locale(@user.preferred_locale) do
      mail(to: @user.email, subject: I18n.t("invitations.mailer.subject", academy: @academy.academy_name))
    end
  end
end
