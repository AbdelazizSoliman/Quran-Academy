module AccountInvitations
  class CreateAndSend
    Result = Data.define(:invitation, :token, :delivery)

    def initialize(user:, actor:)
      @user = user
      @actor = actor
    end

    def call
      raw_token = Token.generate
      invitation = create_invitation(raw_token)
      delivery = deliver(invitation, raw_token)
      Result.new(invitation:, token: raw_token, delivery:)
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

    def deliver(invitation, raw_token)
      Notifications::InvitationDelivery.new(invitation:, token: raw_token, actor: @actor).call
    end

    def event!(invitation, event_type, before_data: {}, after_data: {})
      invitation.events.create!(actor: @actor, event_type:, before_data:, after_data:)
    end
  end
end
