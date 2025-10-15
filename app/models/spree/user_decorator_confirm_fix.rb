# frozen_string_literal: true

# Fix missing `confirmed_at` errors for Spree::User when using spree_auth_devise
# This avoids NameError or Confirmable callback issues during build.

module Spree
  module UserDecoratorConfirmFix
    def confirmed_at
      nil
    end

    def confirmed?
      true
    end
  end
end

Spree::User.prepend(Spree::UserDecoratorConfirmFix)
