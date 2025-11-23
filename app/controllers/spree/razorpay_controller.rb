module Spree
  class RazorpayController < StoreController
    skip_before_action :verify_authenticity_token

    include Spree::RazorPay

    # Step 1: Create Razorpay Order (Kept from the "New" version for security)
    def create_order
      order = Spree::Order.find_by(id: params[:order_id])
      return render json: { success: false, error: 'Order not found' }, status: :not_found unless order

      razorpay_order_id, amount = ::Razorpay::RpOrder::Api.new.create(order.id)

      if razorpay_order_id.present?
        render json: { success: true, razorpay_order_id: razorpay_order_id, amount: amount }
      else
        render json: { success: false, error: "Failed to create Razorpay order" }, status: :unprocessable_entity
      end
    end

    # Step 2: Handle Response
    def razor_response
      # 1. Find the Order
      order = Spree::Order.find_by(number: params[:order_id] || params[:order_number])
      unless order
        flash[:error] = "Order not found."
        return redirect_to checkout_state_path(:payment)
      end

      # 2. Verify Signature
      unless valid_signature?
        flash[:error] = "Payment signature verification failed."
        return redirect_to checkout_state_path(order.state)
      end

      begin
        # 3. Capture and Verify Payment on Razorpay
        razorpay_payment = gateway.verify_and_capture_razorpay_payment(order, razorpay_payment_id)

        # 4. Create Spree Payment Record
        spree_payment = order.razor_payment(razorpay_payment, payment_method, params[:razorpay_signature])

        # 5. FORCE COMPLETE THE PAYMENT
        # This ensures the payment is marked 'completed' immediately
        if spree_payment.respond_to?(:complete!)
          spree_payment.complete!
        end

        # 6. Advance Order State
        # Keep calling next! until the order is fully finalized
        while !order.completed?
          order.next!
        end

        # 7. Force update payment state to 'paid'
        order.update(payment_state: 'paid') if order.respond_to?(:payment_state)

        # 8. Redirect to the specific Token URL
        #flash['order_completed'] = true
        redirect_to completion_route

      rescue StandardError => e
        Rails.logger.error("Razorpay Error: #{e.message}\n#{e.backtrace.join("\n")}")
        flash[:error] = "Payment Error: #{e.message}"
        redirect_to checkout_state_path(order.state)
      end
    end

    private

    def razorpay_payment_id
      params[:razorpay_payment_id] || params.dig(:payment_source, payment_method.id.to_s, :razorpay_payment_id)
    end

    def razorpay_payment
      @razorpay_payment ||= Razorpay::Payment.fetch(razorpay_payment_id)
    end

    def valid_signature?
      p_id = payment_method.id.to_s
      r_order_id = params[:razorpay_order_id] || params.dig(:payment_source, p_id, :razorpay_order_id)
      r_pay_id   = razorpay_payment_id
      r_sig      = params[:razorpay_signature] || params.dig(:payment_source, p_id, :razorpay_signature)

      Razorpay::Utility.verify_payment_signature(
        razorpay_order_id: r_order_id,
        razorpay_payment_id: r_pay_id,
        razorpay_signature: r_sig
      )
    rescue Razorpay::Error => e
      Rails.logger.error("Razorpay signature verification failed: #{e.message}")
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
      # Retrieve the guest token (supports both old and new Spree versions)
      token = order.respond_to?(:guest_token) ? order.guest_token : order.token

      if token.present?
        # Manually construct the URL: /checkout/TOKEN/complete
        "/checkout/#{token}/complete"
      else
        # Fallback if no token exists (standard logged-in user path)
        spree.order_path(order)
      end
    end
  end
end
