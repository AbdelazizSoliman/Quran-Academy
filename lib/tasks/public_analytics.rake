namespace :analytics do
  desc "Delete first-party analytics events older than 90 days"
  task prune: :environment do
    deleted = PublicAnalyticsEvent.where(occurred_at: ...PublicAnalyticsEvent.retention_cutoff).delete_all
    puts "Deleted #{deleted} analytics events"
  end
end
