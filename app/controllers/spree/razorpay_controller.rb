module Spree
  class RazorpayController < StoreController
    skip_before_action :verify_authenticity_token

    include Spree::RazorPay

    # ================================
    # STEP 1: CREATE RAZORPAY ORDER
    # ================================
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

    # ================================
    # STEP 2: HANDLE PAYMENT CALLBACK
    # ================================
    def razor_response
      order = Spree::Order.find_by(number: params[:order_id] || params[:order_number])

      unless order
        flash[:error] = "Order not found."
        return redirect_to checkout_state_path(:payment)
      end

      # 1. Verify Signature
      unless valid_signature?
        flash[:error] = "Payment signature verification failed."
        return redirect_to checkout_state_path(order.state)
      end

      # BEGIN SECURE PROCESSING
      begin
        # 2. Razorpay capture + validation
        razorpay_payment = gateway.verify_and_capture_razorpay_payment(order, razorpay_payment_id)

        # 3. Create Spree payment record
        spree_payment = order.razor_payment(
          razorpay_payment,
          payment_method,
          params[:razorpay_signature]
        )

        # 4. Mark payment completed (safe)
        spree_payment.complete! if spree_payment.respond_to?(:complete!)

        # 5. SAFELY ADVANCE ORDER (idempotent)
        unless order.completed?
          order.next! while !order.completed? && order.can_next?
        end

        # 6. Ensure payment_state = paid
        order.update_columns(payment_state: "paid")

        # 7. Redirect to token-based completion route
        redirect_to completion_route

      rescue StateMachines::InvalidTransition => e
        # ORDER WAS ALREADY COMPLETED → SAFE FALLBACK
        Rails.logger.warn("Order already completed. Skipping next! Error: #{e.message}")
        return redirect_to completion_route

      rescue StandardError => e
        Rails.logger.error("Razorpay Error: #{e.message}\n#{e.backtrace.join("\n")}")
        flash[:error] = "Payment Error: #{e.message}"
        redirect_to checkout_state_path(order.state)
      end
    end

    private

    # -------------------------------
    # HELPERS
    # -------------------------------

    def razorpay_payment_id
      params[:razorpay_payment_id] ||
        params.dig(:payment_source, payment_method.id.to_s, :razorpay_payment_id)
    end

    def razorpay_payment
      @razorpay_payment ||= Razorpay::Payment.fetch(razorpay_payment_id)
    end

    def valid_signature?
      p_id = payment_method.id.to_s

      r_order_id = params[:razorpay_order_id] ||
                   params.dig(:payment_source, p_id, :razorpay_order_id)

      r_pay_id = razorpay_payment_id

      r_sig = params[:razorpay_signature] ||
              params.dig(:payment_source, p_id, :razorpay_signature)

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
      @payment_method ||= Spree::PaymentMethod.find_by(id: params[:payment_method_id]) ||
                           Spree::PaymentMethod.find_by(type: 'Spree::Gateway::RazorpayGateway')
    end

    def gateway
      payment_method
    end

    def order
      @order ||= Spree::Order.find_by(number: params[:order_id] || params[:order_number])
    end

    # -------------------------------
    # FIXED COMPLETION ROUTE
    # -------------------------------
    def completion_route
      token = order.respond_to?(:guest_token) ? order.guest_token : order.token

      if token.present?
        # The correct URL is /checkout/<token>/complete
        "/checkout/#{token}/complete"
      else
        # Logged-in user fallback
        spree.order_path(order)
      end
    end
  end
end
