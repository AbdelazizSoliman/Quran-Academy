module AccountInvitations
  class Resend
    Result = Data.define(:invitation, :token)

    def initialize(invitation:, actor:)
      @invitation = invitation
      @actor = actor
    end

    def call
      raw_token = Token.generate
      rotate_token(raw_token)
      AccountInvitationMailer.with(invitation: @invitation, token: raw_token).invitation_email.deliver_now
      Result.new(invitation: @invitation, token: raw_token)
    rescue ActiveRecord::RecordInvalid => e
      @invitation.errors.merge!(e.record.errors)
      Result.new(invitation: @invitation, token: nil)
    end

    private

    def rotate_token(raw_token)
      @invitation.with_lock do
        raise ActiveRecord::RecordInvalid, @invitation if @invitation.accepted? || @invitation.cancelled?

        previous = @invitation.status
        now = Time.current
        @invitation.update!(token_digest: Token.digest(raw_token), status: "sent",
                            expires_at: AcademySetting.current.invitation_expires_after_hours.hours.from_now,
                            sent_at: now, last_sent_at: now, resent_count: @invitation.resent_count + 1)
        @invitation.events.create!(actor: @actor, event_type: "resent",
                                   before_data: { "status" => previous }, after_data: { "status" => "sent" })
      end
    end
  end
end
