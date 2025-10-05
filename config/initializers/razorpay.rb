# config/initializers/razorpay.rb

# Only run if spree_razorpay_checkout is loaded
if defined?(Spree::RazorpayCheckout)
  Spree::Config.configure do |config|
    config.razorpay_enabled = true
    # Add any other Razorpay-related config here
    # e.g., config.razorpay_key = ENV['RAZORPAY_KEY']
  end
end
