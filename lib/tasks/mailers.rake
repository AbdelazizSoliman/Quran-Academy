namespace :mailers do
  desc "Send a non-persistent invitation delivery test to EMAIL"
  task test_invitation: :environment do
    recipient = ENV.fetch("EMAIL")
    abort "EMAIL must be a valid email address" unless recipient.match?(URI::MailTo::EMAIL_REGEXP)

    user = User.new(first_name: "Render", last_name: "Email Test", email: recipient,
                    role: :staff, status: :pending, preferred_locale: ENV.fetch("LOCALE", "en"),
                    time_zone: AcademySetting.current.default_time_zone)
    invitation = AccountInvitation.new(
      user:, expires_at: AcademySetting.current.invitation_expires_after_hours.hours.from_now, status: "sent"
    )
    token = AccountInvitations::Token.generate

    AccountInvitationMailer.with(invitation:, token:).invitation_email.deliver_now
    puts "Invitation test email accepted for delivery to #{recipient}."
  end
end
