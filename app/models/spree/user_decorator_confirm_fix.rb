# frozen_string_literal: true

module Spree
  module UserConfirmFix
    def self.prepended(base)
      # ensure we skip confirmation checks safely
      base.class_eval do
        skip_callback :create, :after, :send_on_create_confirmation_instructions, if: -> { !respond_to?(:confirmed_at) }
      end
    end
  end
end

Spree::User.prepend(Spree::UserConfirmFix)
