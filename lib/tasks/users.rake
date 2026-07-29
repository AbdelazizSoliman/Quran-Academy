namespace :users do
  desc "Create the first active administrator from ADMIN_* environment variables"
  task create_admin: :environment do
    required = %w[ADMIN_EMAIL ADMIN_PASSWORD ADMIN_FIRST_NAME ADMIN_LAST_NAME]
    missing = required.select { |key| ENV[key].blank? }
    raise "Missing required environment variables: #{missing.join(', ')}" if missing.any?

    email = ENV.fetch("ADMIN_EMAIL").strip.downcase
    raise "A user with email #{email} already exists; no changes were made." if User.exists?(email:)

    user = User.create!(
      email:,
      password: ENV.fetch("ADMIN_PASSWORD"),
      password_confirmation: ENV.fetch("ADMIN_PASSWORD"),
      first_name: ENV.fetch("ADMIN_FIRST_NAME"),
      last_name: ENV.fetch("ADMIN_LAST_NAME"),
      role: :admin,
      status: :active,
      preferred_locale: "ar",
      time_zone: "Cairo"
    )

    puts "Administrator account created for #{user.email}."
  end
end
