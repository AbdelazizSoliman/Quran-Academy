module ProductionMailerConfiguration
  module_function

  def default_url_options(env = ENV)
    {
      host: env.fetch("APP_HOST"),
      protocol: env.fetch("DEFAULT_URL_OPTIONS_PROTOCOL", "https")
    }
  end

  def smtp_settings(env = ENV)
    {
      address: env.fetch("SMTP_ADDRESS", "smtp.gmail.com"),
      port: Integer(env.fetch("SMTP_PORT", "587"), 10),
      domain: env.fetch("SMTP_DOMAIN", "gmail.com"),
      user_name: env.fetch("SMTP_USERNAME"),
      password: env.fetch("SMTP_PASSWORD"),
      authentication: env.fetch("SMTP_AUTHENTICATION", "plain"),
      enable_starttls_auto: boolean(env.fetch("SMTP_ENABLE_STARTTLS_AUTO", "true"))
    }
  end

  def sender(env = ENV) = env.fetch("MAILER_SENDER")

  def boolean(value)
    return true if value.to_s.casecmp?("true")
    return false if value.to_s.casecmp?("false")

    raise ArgumentError, "SMTP_ENABLE_STARTTLS_AUTO must be true or false"
  end
end
