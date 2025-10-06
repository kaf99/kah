require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Code is not reloaded between requests.
  config.enable_reloading = false
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Store uploaded files locally (change to :amazon later if using S3).
  config.active_storage.service = :local
  config.active_storage.service = :backblaze

  # SSL configuration
  config.assume_ssl = true
  config.force_ssl = true

  # Logging setup
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  # Caching setup
  if ENV['REDIS_CACHE_URL'].present?
    cache_servers = ENV['REDIS_CACHE_URL'].split(',')
    config.cache_store = :redis_cache_store, {
      url: cache_servers,
      connect_timeout: 30,
      read_timeout: 0.2,
      write_timeout: 0.2,
      reconnect_attempts: 2,
    }
  else
    config.cache_store = :memory_store
  end

  # blackbaze block till end if not work then delete
  if ENV['SKIP_S3_VALIDATION'] == 'true'
  puts "⚙️ Skipping S3 validation during assets precompile"
  else
  Rails.application.config.active_storage.service = :backblaze
  end
  
  # Background jobs
  config.active_job.queue_adapter = :sidekiq

  # Host configuration
  config.action_controller.asset_host = "https://www.nozfragrances.com"
  Rails.application.routes.default_url_options[:host] = "www.nozfragrances.com"
  Rails.application.routes.default_url_options[:protocol] = "https"

  # I18n fallback
  config.i18n.fallbacks = true

  # Database
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # Mailer (Postmark)
  config.action_mailer.delivery_method = :postmark
  config.action_mailer.postmark_settings = { api_token: ENV["POSTMARK_API_TOKEN"] }
  config.action_mailer.default_url_options = { host: 'nozfragrances.com', protocol: 'https' }
  config.action_mailer.asset_host = 'https://www.nozfragrances.com'
  config.action_mailer.raise_delivery_errors = true
end
