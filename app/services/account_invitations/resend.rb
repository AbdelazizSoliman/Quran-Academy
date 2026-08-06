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
      mark_sent if deliver(raw_token).succeeded.include?("email")
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
        @invitation.update!(token_digest: Token.digest(raw_token), status: "pending",
                            expires_at: AcademySetting.current.invitation_expires_after_hours.hours.from_now,
                            resent_count: @invitation.resent_count + 1)
        @invitation.events.create!(actor: @actor, event_type: "resent",
                                   before_data: { "status" => previous }, after_data: { "status" => "pending" })
      end
    end

    def deliver(raw_token)
      Notifications::InvitationDelivery.new(invitation: @invitation, token: raw_token, actor: @actor).call
    end

    def mark_sent
      @invitation.with_lock do
        now = Time.current
        @invitation.update!(status: "sent", sent_at: now, last_sent_at: now)
      end
    end
  end
end
