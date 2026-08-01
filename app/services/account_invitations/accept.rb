module AccountInvitations
  class Accept
    def initialize(invitation:, password:, password_confirmation:, ip:, user_agent:)
      @invitation = invitation
      @password = password
      @password_confirmation = password_confirmation
      @ip = ip
      @user_agent = user_agent
    end

    def call
      @invitation.with_lock { accept! }
      @invitation
    rescue ActiveRecord::RecordInvalid => e
      @invitation.errors.merge!(e.record.errors) unless e.record == @invitation
      @invitation
    end

    private

    def accept!
      return expire! if @invitation.expires_at.past? && !@invitation.accepted?

      unless @invitation.usable?
        @invitation.errors.add(:base, :not_usable)
        return
      end

      AccountInvitation.transaction { activate_user_and_invitation! }
    end

    def activate_user_and_invitation!
      user = @invitation.user
      user.update!(password: @password, password_confirmation: @password_confirmation, status: "active")
      @invitation.update!(acceptance_attributes)
      @invitation.events.create!(actor: user, event_type: "accepted",
                                 before_data: { "status" => "sent" }, after_data: { "status" => "accepted" })
    end

    def acceptance_attributes
      { status: "accepted", accepted_at: Time.current, token_digest: Token.digest(Token.generate),
        accepted_ip: @ip, accepted_user_agent: @user_agent.to_s.first(500) }
    end

    def expire!
      previous = @invitation.status
      @invitation.update!(status: "expired")
      @invitation.events.create!(event_type: "expired", before_data: { "status" => previous },
                                 after_data: { "status" => "expired" })
      @invitation.errors.add(:base, :expired)
    end
  end
end
