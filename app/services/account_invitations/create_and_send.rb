module AccountInvitations
  class CreateAndSend
    Result = Data.define(:invitation, :token)

    def initialize(user:, actor:)
      @user = user
      @actor = actor
    end

    def call
      raw_token = Token.generate
      invitation = create_invitation(raw_token)
      AccountInvitationMailer.with(invitation:, token: raw_token).invitation_email.deliver_now
      mark_sent(invitation)
      Result.new(invitation:, token: raw_token)
    end

    private

    def create_invitation(raw_token)
      AccountInvitation.transaction do
        invitation = AccountInvitation.create!(
          user: @user, created_by: @actor, token_digest: Token.digest(raw_token),
          expires_at: AcademySetting.current.invitation_expires_after_hours.hours.from_now
        )
        event!(invitation, "created", after_data: { "status" => invitation.status })
        invitation
      end
    end

    def mark_sent(invitation)
      invitation.with_lock do
        now = Time.current
        invitation.update!(status: "sent", sent_at: now, last_sent_at: now)
        event!(invitation, "sent", before_data: { "status" => "pending" }, after_data: { "status" => "sent" })
      end
    end

    def event!(invitation, event_type, before_data: {}, after_data: {})
      invitation.events.create!(actor: @actor, event_type:, before_data:, after_data:)
    end
  end
end
