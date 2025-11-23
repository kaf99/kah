# config/initializers/razorpay.rb

# Enable Razorpay inside Spree if the extension is loaded
if defined?(Spree::RazorpayCheckout)
  Spree::Config.configure do |config|
    config.razorpay_enabled = true
  end
end

# Initialize Razorpay safely
if defined?(Razorpay)
  key_id     = ENV["RAZORPAY_KEY_ID"]
  key_secret = ENV["RAZORPAY_KEY_SECRET"]

  # During asset:precompile (Docker build), ENV is missing → skip initialization
  if key_id.present? && key_secret.present?
    begin
      Razorpay.setup(key_id, key_secret)
      Rails.logger.info("Razorpay initialized successfully.")
    rescue => e
      Rails.logger.warn("Razorpay initialization failed: #{e.message}")
    end
  else
    Rails.logger.warn("Razorpay credentials missing – skipping Razorpay setup during build.")
  end
end
