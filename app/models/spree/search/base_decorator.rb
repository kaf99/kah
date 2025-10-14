# frozen_string_literal: true

module Spree
  module Search
    module BaseDecorator
      def get_base_scope
        base_scope = super

        if keywords.present?
          # make search keyword lowercase to match our ransacker
          normalized = keywords.downcase.strip

          base_scope = base_scope.ransack({
            m: 'or',
            name_i_cont: normalized,
            description_i_cont: normalized,
            tag_names_i_cont: normalized
          }).result
        end

        base_scope
      end
    end
  end
end
