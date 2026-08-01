module AccountInvitations
  class Cancel
    def initialize(invitation:, actor:)
      @invitation = invitation
      @actor = actor
    end

    def call
      @invitation.with_lock do
        return @invitation if @invitation.cancelled?

        return reject_accepted if @invitation.accepted?

        cancel!
      end
      @invitation
    end

    private

    def reject_accepted
      @invitation.errors.add(:base, :already_accepted)
      @invitation
    end

    def cancel!
      previous = @invitation.status
      @invitation.update!(status: "cancelled")
      @invitation.events.create!(actor: @actor, event_type: "cancelled",
                                 before_data: { "status" => previous }, after_data: { "status" => "cancelled" })
    end
  end
end
