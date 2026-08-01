require "rails_helper"
require Rails.root.join("config/production_mailer_configuration")

RSpec.describe ProductionMailerConfiguration do
  let(:environment) do
    {
      "APP_HOST" => "quran-academy-igl2.onrender.com",
      "DEFAULT_URL_OPTIONS_PROTOCOL" => "https",
      "MAILER_SENDER" => "sender@example.test",
      "SMTP_USERNAME" => "smtp-user@example.test",
      "SMTP_PASSWORD" => "placeholder-app-password"
    }
  end

  it "builds HTTPS Render URL options" do
    expect(described_class.default_url_options(environment)).to eq(
      host: "quran-academy-igl2.onrender.com", protocol: "https"
    )
  end

  it "builds Gmail SMTP settings with typed secure defaults" do
    expect(described_class.smtp_settings(environment)).to eq(
      address: "smtp.gmail.com", port: 587, domain: "gmail.com",
      user_name: "smtp-user@example.test", password: "placeholder-app-password",
      authentication: "plain", enable_starttls_auto: true
    )
  end

  it "parses explicit ports and booleans strictly" do
    custom = environment.merge("SMTP_PORT" => "2525", "SMTP_ENABLE_STARTTLS_AUTO" => "false")

    expect(described_class.smtp_settings(custom).values_at(:port, :enable_starttls_auto)).to eq([2525, false])
    expect { described_class.boolean("enabled") }.to raise_error(ArgumentError)
  end

  it "requires SMTP credentials, sender, and host" do
    expect { described_class.smtp_settings(environment.except("SMTP_USERNAME")) }.to raise_error(KeyError)
    expect { described_class.smtp_settings(environment.except("SMTP_PASSWORD")) }.to raise_error(KeyError)
    expect { described_class.sender(environment.except("MAILER_SENDER")) }.to raise_error(KeyError)
    expect { described_class.default_url_options(environment.except("APP_HOST")) }.to raise_error(KeyError)
  end

  it "uses MAILER_SENDER consistently for application and Devise mail" do
    expected = ENV.fetch("MAILER_SENDER", "no-reply@quran-academy.example")

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
    expect(example).to include("SMTP_PASSWORD=replace-with-a-google-app-password")
    expect(Rails.root.join("config/environments/production.rb").read).not_to match(/password:\s*["'][^"']+/)
  end
end
