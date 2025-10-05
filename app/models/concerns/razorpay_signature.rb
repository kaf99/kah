# app/models/concerns/razorpay_signature.rb
module RazorpaySignature
  extend ActiveSupport::Concern

  # Validate Razorpay payment signature
  def valid_signature?(order_id, payment_id, signature)
    data = "#{order_id}|#{payment_id}"

    expected_signature = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'),
      Rails.application.credentials.dig(:razorpay, :secret),
      data
    )

    # Use secure_compare to avoid timing attacks
    ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
  end
end
