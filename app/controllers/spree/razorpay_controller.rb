module Spree
class RazorpayController < StoreController
skip_before_action :verify_authenticity_token

include Spree::RazorPay

# Step 1: Create Razorpay Order
def create_order
  Rails.logger.info "Params received for create_order: #{params.inspect}"
  order = Spree::Order.find_by(id: params[:order_id])
  unless order
    Rails.logger.error "Order not found with id #{params[:order_id]}"
    return render json: { success: false, error: 'Order not found' }, status: :not_found
  end

  begin
    razorpay_order_id, amount = ::Razorpay::RpOrder::Api.new.create(order.id)
    Rails.logger.info "Razorpay order creation result: #{razorpay_order_id}, amount: #{amount}"

    if razorpay_order_id.present?
      render json: { success: true, razorpay_order_id: razorpay_order_id, amount: amount }
    else
      Rails.logger.error "Failed to create Razorpay order for order #{order.id}"
      render json: { success: false, error: "Failed to create Razorpay order" }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error creating Razorpay order: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { success: false, error: e.message }, status: :internal_server_error
  end
end

# Step 2: Handle Response
def razor_response
  Rails.logger.info "Params received for razor_response: #{params.inspect}"
  
  order = Spree::Order.find_by(number: params[:order_id] || params[:order_number])
  unless order
    Rails.logger.error "Order not found with number #{params[:order_id] || params[:order_number]}"
    flash[:error] = "Order not found."
    return redirect_to checkout_state_path(:payment)
  end

  unless valid_signature?
    Rails.logger.error "Payment signature verification failed for order #{order.number}"
    flash[:error] = "Payment signature verification failed."
    return redirect_to checkout_state_path(order.state)
  end

  begin
    Rails.logger.info "Capturing Razorpay payment for order #{order.number}"
    razorpay_payment = gateway.verify_and_capture_razorpay_payment(order, razorpay_payment_id)
    Rails.logger.info "Razorpay payment fetched: #{razorpay_payment.inspect}"

    spree_payment = order.razor_payment(razorpay_payment, payment_method, params[:razorpay_signature])
    Rails.logger.info "Spree payment created: #{spree_payment.inspect}"

    spree_payment.complete! if spree_payment.respond_to?(:complete!)
    Rails.logger.info "Spree payment marked complete"

    while !order.completed?
      order.next!
      Rails.logger.info "Order state advanced to #{order.state}"
    end

    order.update(payment_state: 'paid') if order.respond_to?(:payment_state)
    Rails.logger.info "Order payment_state updated to 'paid'"

    redirect_to completion_route
  rescue StandardError => e
    Rails.logger.error "Razorpay processing error: #{e.message}\n#{e.backtrace.join("\n")}"
    flash[:error] = "Payment Error: #{e.message}"
    redirect_to checkout_state_path(order.state)
  end
end

private

def razorpay_payment_id
  id = params[:razorpay_payment_id] || params.dig(:payment_source, payment_method.id.to_s, :razorpay_payment_id)
  Rails.logger.info "Resolved razorpay_payment_id: #{id}"
  id
end

def razorpay_payment
  @razorpay_payment ||= Razorpay::Payment.fetch(razorpay_payment_id)
end

def valid_signature?
  p_id = payment_method.id.to_s
  r_order_id = params[:razorpay_order_id] || params.dig(:payment_source, p_id, :razorpay_order_id)
  r_pay_id   = razorpay_payment_id
  r_sig      = params[:razorpay_signature] || params.dig(:payment_source, p_id, :razorpay_signature)

  Rails.logger.info "Verifying signature with razorpay_order_id=#{r_order_id}, payment_id=#{r_pay_id}, signature=#{r_sig}"

  Razorpay::Utility.verify_payment_signature(
    razorpay_order_id: r_order_id,
    razorpay_payment_id: r_pay_id,
    razorpay_signature: r_sig
  )
rescue Razorpay::Error => e
  Rails.logger.error "Razorpay signature verification failed: #{e.message}"
  false
end

def payment_method
  @payment_method ||= Spree::PaymentMethod.find_by(id: params[:payment_method_id]) || Spree::PaymentMethod.find_by(type: 'Spree::Gateway::RazorpayGateway')
end

def gateway
  payment_method
end

def order
  @order ||= Spree::Order.find_by(number: params[:order_id] || params[:order_number])
end

def completion_route
  token = order.respond_to?(:guest_token) ? order.guest_token : order.token
  if token.present?
    "/checkout/#{token}/complete"
  else
    spree.order_path(order)
  end
end

end
end
