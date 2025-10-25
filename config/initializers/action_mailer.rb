# Use SendGrid SMTP as the default mailer
Rails.application.config.action_mailer.delivery_method = :smtp

Rails.application.config.action_mailer.smtp_settings = {
  address:              'smtp.sendgrid.net',
  port:                 587,
  domain:               'nozfragrances.com',
  user_name:            'apikey',                # literal 'apikey'
  password:             ENV['SENDGRID_API_KEY'], # SendGrid API key from environment
  authentication:       :plain,
  enable_starttls_auto: true
}

Rails.application.config.action_mailer.default_url_options = { host: "nozfragrances.com", protocol: "https" }
Rails.application.config.action_mailer.asset_host = "https://www.nozfragrances.com"
Rails.application.config.action_mailer.raise_delivery_errors = true
