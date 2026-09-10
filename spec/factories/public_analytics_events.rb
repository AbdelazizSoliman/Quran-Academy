FactoryBot.define do
  factory :public_analytics_event do
    event_type { "page_view" }
    occurred_at { Time.current }
    locale { "en" }
    path { "/en" }
    source_path { "home" }
    visitor_token { SecureRandom.hex(16) }
  end
end
