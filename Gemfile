source "https://rubygems.org"
ruby '3.3.0'

gem 'rails', '~> 8.0.0'
gem "pg", "~> 1.6"
gem "puma", ">= 5.0"

# Payment Integrations
gem "spree_stripe"
gem "spree_paypal_checkout", "~> 0.5"
gem 'spree_razorpay_checkout'
gem 'razorpay'
gem 'spree_product_reviews', git: 'https://github.com/kaf99/spree_product_reviews.git', branch: 'main'

# --- Search ---
gem 'elasticsearch', '~> 8.10' 
gem 'searchkick', '~> 5.5'


#email-marketing
gem 'postmark-rails'

gem 'dartsass-rails', '0.5.1'

# JS + Hotwire
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# JSON & API
gem "jbuilder"

# JS runtime
gem 'mini_racer', platforms: :ruby

# Redis / Background jobs
gem "redis", ">= 4.0.1"
gem 'sidekiq'

# Auth
gem "devise"

# Monitoring & Error tracking
gem 'sentry-ruby'
gem 'sentry-rails'
gem 'sentry-sidekiq'

# Image uploads
gem "image_processing", "~> 1.13"

# Spree gems
spree_opts = '~> 5.1'
gem "spree", spree_opts
gem "spree_emails", spree_opts
gem "spree_sample", spree_opts
gem "spree_admin", spree_opts
gem "spree_storefront", spree_opts
gem "spree_i18n"
gem "spree_google_analytics", "~> 1.0"
gem "spree_klaviyo", "~> 1.0"

# Spree Extensions
# Preview emails in the browser
group :development do
  gem "letter_opener"
end

# Development & Test
group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem 'brakeman'
  gem 'dotenv-rails', '~> 3.1'
  gem 'rubocop', '~> 1.23'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'pry'
  gem 'pry-remote'
  gem 'selenium-webdriver', '~> 4.7.1'
  gem 'sassc-rails' # Needed for asset compilation
end

group :development do
  gem "foreman"
  gem "web-console"
  gem 'solargraph'
  gem 'solargraph-rails'
  gem 'ruby-lsp'
  gem 'ruby-lsp-rails'
end

group :test do
  gem 'spree_dev_tools'
  gem 'capybara', '~> 3.39'
  gem 'capybara-screenshot', '~> 1.0'
  gem 'email_spec'
  gem 'factory_bot'
  gem 'factory_bot_rails'
  gem 'database_cleaner'
  gem 'rspec-activemodel-mocks', '~> 1.0'
  gem 'rspec-rails', '~> 6.1'
  gem 'rspec-retry'
  gem 'rspec_junit_formatter'
  gem 'rubocop-rspec'
  gem 'jsonapi-rspec'
  gem 'simplecov'
  gem 'webmock', '~> 3.7', require: false
  gem 'timecop'
  gem 'rails-controller-testing'
  gem 'webdrivers', '~> 5.0'
end

# Windows only
gem "tzinfo-data", platforms: %i[windows jruby]

# Boot optimization
gem "bootsnap", require: false
