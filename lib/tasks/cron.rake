namespace :cron do
  desc "Run bounded academy reminder and recurring lesson work"
  task academy: :environment do
    AcademyCron.new.call
  end
end
