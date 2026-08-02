module ProductionMailerConfiguration
  module_function

  def default_url_options(env = ENV)
    {
      host: env.fetch("APP_HOST"),
      protocol: env.fetch("DEFAULT_URL_OPTIONS_PROTOCOL", "https")
    }
  end

  def sender(env = ENV) = env.fetch("MAILER_SENDER")
end
