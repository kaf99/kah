class RazorpayWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token  # Webhooks come from Razorpay, not a browser

  def payment_completed
    # Parse webhook payload
    payload = JSON.parse(request.body.read)

    order_number = payload.dig("payload", "payment", "entity", "notes", "order_number")
    razorpay_payment_id = payload.dig("payload", "payment", "entity", "id")
    payment_amount = payload.dig("payload", "payment", "entity", "amount").to_f / 100  # amount in INR

    order = Spree::Order.find_by(number: order_number)
    return head :not_found unless order

    pm = Spree::PaymentMethod.find_by(type: "Spree::Gateway::RazorpayGateway", active: true)
    payment = order.payments.create!(
      payment_method: pm,
      amount: payment_amount,
      response_code: razorpay_payment_id
    )

    payment.complete!
    order.update(payment_state: "paid")
    order.next! until order.state == "complete"

    head :ok
  end
end
