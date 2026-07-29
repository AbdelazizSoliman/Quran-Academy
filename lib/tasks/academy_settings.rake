namespace :academy_settings do
  desc "Ensure the singleton academy settings record exists"
  task ensure: :environment do
    setting = AcademySetting.current
    puts "Academy settings ready (id=#{setting.id})."
  end
end
