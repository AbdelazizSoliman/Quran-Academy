module AccountInvitations
  # Idempotently marks an invitation as sent. Shared by the synchronous email path and the
  # asynchronous WhatsApp path so whichever channel actually succeeds first — in either order —
  # marks the invitation usable exactly once, without a duplicate update or audit event.
  class MarkSent
    def self.call(invitation:, actor:)
      invitation.with_lock do
        next if invitation.sent? || invitation.accepted?

        now = Time.current
        previous = invitation.status
        invitation.update!(status: "sent", sent_at: invitation.sent_at || now, last_sent_at: now)
        invitation.events.create!(actor:, event_type: "sent",
                                  before_data: { "status" => previous }, after_data: { "status" => "sent" })
      end
    end
  end
end
