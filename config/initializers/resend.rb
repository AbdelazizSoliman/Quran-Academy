Resend.api_key = if Rails.env.production?
                   ENV.fetch("RESEND_API_KEY")
                 else
                   ENV.fetch("RESEND_API_KEY", nil)
                 end
