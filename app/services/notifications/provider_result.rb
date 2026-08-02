module Notifications
  ProviderResult = Data.define(:success?, :provider_message_id, :response, :http_status, :provider_status,
                               :error_code, :error_message)
end
