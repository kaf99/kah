# app/controllers/spree/razorpay_controller.rb

class Spree::RazorpayController < Spree::StoreController
skip_before_action :verify_authenticity_token, only: [:razor_response]
skip_before_action :redirect_to_password, only: [:razor_response]

require 'razorpay'

# POST /razorpay/callback

def razor_response
Rails.logger.info "Razorpay webhook received: #{params.to_unsafe_h}"

```
payment_data = params.dig(:payload, :payment, :entity)
razor_signature = request.headers['X-Razorpay-Signature']

# Verify webhook signature
secret = ENV['RAZORPAY_WEBHOOK_SECRET']
begin
  Razorpay::Utility.verify_webhook_signature(request.raw_post, razor_signature, secret)
rescue Razorpay::Error::SignatureVerificationError => e
  Rails.logger.error "Razorpay signature verification failed: #{e.message}"
  return head :bad_request
end

order = Spree::Order.find_by(number: payment_data[:order_id])
pm = Spree::PaymentMethod.find_by(type: "Spree::Gateway::RazorpayGateway", active: true)

if order.nil? || pm.nil?
  Rails.logger.error "Order or PaymentMethod not found: #{payment_data[:order_id]}"
  return head :not_found
end

begin
  # Create payment in Spree
  sp = order.razor_payment(OpenStruct.new(payment_data), pm, razor_signature)
  sp.complete!
  order.next! until order.completed?
  order.update(payment_state: "paid", completed_at: Time.current)
  Rails.logger.info "Order processed successfully: #{order.number}"
  head :ok
rescue => e
  Rails.logger.error "Razorpay webhook processing error: #{e.message}\n#{e.backtrace.join("\n")}"
  head :internal_server_error
end
```

end

# GET /razorpay/new_order

# Optional: endpoint to generate Razorpay order before checkout

def new_order
order = Spree::Order.last
pm = Spree::PaymentMethod.find_by(type: "Spree::Gateway::RazorpayGateway", active: true)

```
if order.nil? || pm.nil?
  render json: { error: "Order or payment method not found" }, status: :not_found
  return
end

# Convert amount to paise (integer)
amount_in_paise = (order.total * 100).to_i

begin
  razor_order = Razorpay::Order.create(
    amount: amount_in_paise,
    currency: "INR",
    receipt: order.number,
    payment_capture: 1
  )
  render json: { razorpay_order_id: razor_order.id, amount: amount_in_paise, currency: "INR" }
rescue => e
  Rails.logger.error "Error creating Razorpay order: #{e.message}\n#{e.backtrace.join("\n")}"
  render json: { error: "Failed to create Razorpay order" }, status: :internal_server_error
end
```

end
end
