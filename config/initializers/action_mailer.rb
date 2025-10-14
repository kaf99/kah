# Ensure Postmark is configured before Spree mailers load
Rails.application.config.action_mailer.delivery_method = :postmark
Rails.application.config.action_mailer.postmark_settings = { api_token: ENV.fetch("POSTMARK_API_TOKEN", nil) }
Rails.application.config.action_mailer.default_url_options = { host: "nozfragrances.com", protocol: "https" }
Rails.application.config.action_mailer.asset_host = "https://www.nozfragrances.com"
Rails.application.config.action_mailer.raise_delivery_errors = true
