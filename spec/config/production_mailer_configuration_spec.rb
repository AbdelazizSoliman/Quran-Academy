require "rails_helper"
require Rails.root.join("config/production_mailer_configuration")

RSpec.describe ProductionMailerConfiguration do
  let(:environment) do
    {
      "APP_HOST" => "quran-academy-igl2.onrender.com",
      "DEFAULT_URL_OPTIONS_PROTOCOL" => "https",
      "MAILER_SENDER" => "sender@example.test"
    }
  end

  it "builds HTTPS Render URL options" do
    expect(described_class.default_url_options(environment)).to eq(
      host: "quran-academy-igl2.onrender.com", protocol: "https"
    )
  end

  it "requires a sender and host" do
    expect { described_class.sender(environment.except("MAILER_SENDER")) }.to raise_error(KeyError)
    expect { described_class.default_url_options(environment.except("APP_HOST")) }.to raise_error(KeyError)
  end

  it "uses MAILER_SENDER consistently for application and Devise mail" do
    expected = ENV.fetch("MAILER_SENDER", "onboarding@resend.dev")

    expect(ApplicationMailer.default[:from]).to eq(expected)
    expect(Devise.mailer_sender).to eq(expected)
  end

  it "generates invitation URLs with the configured HTTPS host" do
    invitation = create(:account_invitation, user: create(:user, :pending, :english_locale))
    original_options = AccountInvitationMailer.default_url_options
    AccountInvitationMailer.default_url_options = described_class.default_url_options(environment)

    mail = AccountInvitationMailer.with(invitation:, token: "safe-test-token").invitation_email
    body = mail.text_part.body.decoded
    expect(body).to include("https://quran-academy-igl2.onrender.com/account/invitation/safe-test-token")
  ensure
    AccountInvitationMailer.default_url_options = original_options
  end

  it "keeps repository examples free of credential values" do
    example = Rails.root.join(".env.example").read

    expect(example).not_to include("quran-academy-igl2.onrender.com")
    expect(example).to include("RESEND_API_KEY=\n")
    expect(example).not_to include("SMTP_")
    expect(Rails.root.join("config/environments/production.rb").read).not_to match(/smtp/i)
  end

  it "configures the official Resend ActionMailer transport" do
    production = Rails.root.join("config/environments/production.rb").read

    expect(production).to include("config.action_mailer.delivery_method = :resend")
    expect(Rails.root.join("config/initializers/resend.rb").read).to include('ENV.fetch("RESEND_API_KEY")')
  end
end
