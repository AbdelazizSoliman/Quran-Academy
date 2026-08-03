if ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_DATA", nil))
  raise "Demo data cannot be loaded in production" if Rails.env.production?

  require_relative "seeds/development_seed"
  DevelopmentSeed.call
else
  Rails.logger.debug "Core seeds have no records to create. Use DEMO_DATA=true bin/rails db:seed for local demo data."
end
