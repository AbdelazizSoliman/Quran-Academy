class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_SENDER", "onboarding@resend.dev")
  layout "mailer"
end
