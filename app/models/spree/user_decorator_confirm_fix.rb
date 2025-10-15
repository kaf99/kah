# frozen_string_literal: true

# Fix missing `confirmed_at` errors for Spree::User when using spree_auth_devise
# (some environments or migrations don't include the Devise confirmable fields)

module Spree
  module UserConfirmFix
    def confirmed_at
      nil
    end

    def confirmed?
      true
    end
  end
end

Spree::User.prepend(Spree::UserConfirmFix)
