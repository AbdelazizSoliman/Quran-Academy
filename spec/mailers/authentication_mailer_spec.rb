require "rails_helper"

RSpec.describe AuthenticationMailer do
  it "localizes password reset mail to the user preference" do
    user = create(:user, :english_locale)
    token = user.send_reset_password_instructions
    mail = ActionMailer::Base.deliveries.last

    expect(token).to be_present
    expect(mail.subject).to eq(I18n.t("devise.mailer.reset_password_instructions.subject", locale: :en))
    expect(mail.body.encoded).to include("Set a new password")
  end
end
